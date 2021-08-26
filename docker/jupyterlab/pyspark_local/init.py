# This will trigger initialization of Pyspark
from pyspark.shell import *
# Fix the Spark UI link
from pyspark import SparkContext
from dapla.spark.sparkui import uiWebUrl
SparkContext.uiWebUrl = property(uiWebUrl)