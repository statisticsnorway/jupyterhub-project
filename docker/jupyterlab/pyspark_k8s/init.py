import atexit
import os
import socket
import string
import random
import platform
import warnings
import time
from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from dapla.spark.sparkui import uiWebUrl


def generate_app_name():
    randomId = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    return os.environ["JUPYTERHUB_CLIENT_ID"] + '-' + randomId


def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect((os.environ.get("KUBERNETES_SERVICE_HOST", "8.8.8.8"), 80))
    local_ip = s.getsockname()[0]
    s.close()
    return local_ip


def generate_k8s_pod_name_prefix():
    prefix = f"{os.environ['HOSTNAME']}-{str(time.time_ns())}"
    # Max length of pod name in k8s is 63 chars
    # Spark executors are named by the prefix + executor-nn
    # Where nn are number of executors (1-20)
    # Since Spark 3.3.0 there is a hardcoded limit of 47
    length = len(prefix)
    if length > 47:
        return prefix[length-47:]
    return prefix

# This is similar to /pyspark/shell.py
SparkContext._ensure_initialized()  # type: ignore

try:
    spark = SparkSession.builder.appName(generate_app_name()) \
        .config('spark.submit.deployMode', 'client') \
        .config('spark.driver.host', get_local_ip()) \
        .config('spark.driver.port', os.environ.get("SPARK_DRIVER_PORT", "0")) \
        .config('spark.blockManager.port', os.environ.get("SPARK_BLOCKMANAGER_PORT", "0")) \
        .config('spark.port.maxRetries', os.environ.get("SPARK_PORT_MAX_RETRIES", "0")) \
        .config('spark.executorEnv.JUPYTERHUB_API_TOKEN', os.environ["JUPYTERHUB_API_TOKEN"]) \
        .config('spark.kubernetes.executor.podNamePrefix', generate_k8s_pod_name_prefix()) \
        .config('spark.kubernetes.driver.pod.name', os.environ["HOSTNAME"]) \
        .getOrCreate()
except Exception:
    import sys
    import traceback
    warnings.warn("Failed to initialize Spark session.")
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)

sc = spark.sparkContext
sql = spark.sql
atexit.register(lambda: sc.stop())

# for compatibility
sqlContext = spark._wrapped
sqlCtx = sqlContext

# Fix the Spark UI link
SparkContext.uiWebUrl = property(uiWebUrl)
print(r"""Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /__ / .__/\_,_/_/ /_/\_\   version %s
      /_/
""" % sc.version)
print("Using Python version %s (%s, %s)" % (
    platform.python_version(),
    platform.python_build()[0],
    platform.python_build()[1]))
print("Spark context Web UI available at %s" % (sc.uiWebUrl))
print("Spark context available as 'sc' (master = %s, app id = %s)." % (sc.master, sc.applicationId))
print("SparkSession available as 'spark'.")

# The ./bin/pyspark script stores the old PYTHONSTARTUP value in OLD_PYTHONSTARTUP,
# which allows us to execute the user's PYTHONSTARTUP file:
_pythonstartup = os.environ.get('OLD_PYTHONSTARTUP')
if _pythonstartup and os.path.isfile(_pythonstartup):
    with open(_pythonstartup) as f:
        code = compile(f.read(), _pythonstartup, 'exec')
        exec(code)
