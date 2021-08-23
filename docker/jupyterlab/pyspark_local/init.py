# This will trigger initialization of Pyspark
from pyspark import shell
# Fix the Spark UI link
from dapla.spark.sparkui import uiWebUrl
SparkContext.uiWebUrl = property(uiWebUrl)