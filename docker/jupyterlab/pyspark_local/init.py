import atexit
import os
import string
import random
from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from dapla.spark.sparkextension import load_extensions
from dapla.spark.sparkui import uiWebUrl
from dapla.magics import load_all
from IPython import get_ipython

randomId = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
appName = os.environ["JUPYTERHUB_CLIENT_ID"] + '-' + randomId

spark = SparkSession.builder.appName(appName) \
    .getOrCreate()

# This is similar to /pyspark/shell.py
sc = spark.sparkContext
sql = spark.sql
atexit.register(lambda: sc.stop())

# This registers the custom pyspark extensions
load_extensions()

# Fix the Spark UI link
SparkContext.uiWebUrl = property(uiWebUrl)

# Load dapla magics
load_all(get_ipython())
