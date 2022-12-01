FROM eu.gcr.io/prod-bip/ssb/statistikktjenester/jupyterlab-common:latest

ARG spark_version="3.2.1"
ARG hadoop_version="3.2"
ARG spark_checksum="145ADACF189FECF05FBA3A69841D2804DD66546B11D14FC181AC49D89F3CB5E4FECD9B25F56F0AF767155419CD430838FB651992AEB37D3A6F91E7E009D1F9AE"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy the kernels. (pre-defined kernels are found at /opt/conda/share/jupyter/kernels)
COPY pyspark_k8s /usr/local/share/jupyter/kernels/pyspark_k8s/
COPY pyspark_local /usr/local/share/jupyter/kernels/pyspark_local/
COPY sparkR_k8s/kernel.json /opt/conda/share/jupyter/kernels/ir_k8s/
COPY sparkR_k8s/Rstartup /opt/conda/share/jupyter/kernels/ir_k8s/
COPY sparkR_local/kernel.json /opt/conda/share/jupyter/kernels/ir/
COPY sparkR_local/Rstartup /opt/conda/share/jupyter/kernels/ir/

USER root
# Spark installation
ENV APACHE_SPARK_VERSION="${spark_version}" \
    HADOOP_VERSION="${hadoop_version}"
WORKDIR /tmp
RUN wget -q "https://archive.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    echo "${spark_checksum} *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha512sum -c - && \
    tar xzf "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -C /usr/local --owner root --group root --no-same-owner && \
    rm "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"

WORKDIR /usr/local

# Configure Spark
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH="${PATH}:${SPARK_HOME}/bin"

RUN ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" spark && \
    # Add a link in the before_notebook hook in order to source automatically PYTHONPATH
    mkdir -p /usr/local/bin/before-notebook.d && \
    ln -s "${SPARK_HOME}/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh

# Fix Spark installation for Java 11 and Apache Arrow library
# see: https://github.com/apache/spark/pull/27356, https://spark.apache.org/docs/latest/#downloading
RUN cp -p "${SPARK_HOME}/conf/spark-defaults.conf.template" "${SPARK_HOME}/conf/spark-defaults.conf" && \
    echo 'spark.driver.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true' >> "${SPARK_HOME}/conf/spark-defaults.conf" && \
    echo 'spark.executor.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true' >> "${SPARK_HOME}/conf/spark-defaults.conf"

# Configure IPython system-wide
COPY ipython_kernel_config.py "/etc/ipython/"
RUN fix-permissions "/etc/ipython/"

# See https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html#startup-hooks
COPY env.sh /usr/local/bin/before-notebook.d/env.sh
COPY spark-defaults.conf /tmp/spark-defaults.conf

RUN chown -R $NB_UID /usr/local/share/jupyter/kernels
RUN chown -R $NB_UID /opt/conda/share/jupyter/kernels
RUN chown -R $NB_UID /usr/local/spark/conf/spark-defaults.conf

USER $NB_UID

WORKDIR "${HOME}"

# pipenv is used for keeping track of and loading the specific package dependencies of each repository
# Together with with envkernel Jupyter users can create Jupyter kernels with a different environment.
RUN echo "**** install pipenv envkernel ****" && \
    python3 -m pip install pipenv envkernel

# Customer defined libraries
RUN echo "**** install ssb_spark_tools ****" && \
    python3 -m pip install ssb_spark_tools==0.1.6 && \
    echo "**** install sphinx ****" && \
    python3 -m pip install sphinx sphinx-autodoc-defaultargs sphinx-autodoc-typehints sphinx-rtd-theme && \
    echo "**** install pandas-gbq and correponding google (auth/cloud/bigquery) dependencies " && \
    python3 -m pip install pandas-gbq && \
    echo "**** install Dapla tools" && \
    python3 -m pip install dapla-toolbelt==1.3.5 ssb-datadoc[gcs]==0.2.2 ssb-project-cli==1.0.9 venv-pack && \
    echo "**** install pyspark, pyarrow, gcs libraries" && \
    python3 -m pip install pyspark==${APACHE_SPARK_VERSION} pyarrow google-cloud-storage && \
    echo "**** install nbdev ****" && \
    python3 -m pip install nbdev && \
    python3 -m pip cache purge && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds


COPY ssh-agent-helper.bash /usr/local/bin/ssh-agent-helper.sh
COPY restart-ssh-agent.bash /usr/local/bin/restart-ssh-agent.sh

COPY check-git-config.bash /usr/local/bin/check-git-config.sh

# Copy the GCS connector.
COPY gcs-connector-shaded.jar /jupyter/lib/gcs-connector-hadoop.jar
# Copy the access token provider for the GCS connector
COPY access-token-provider-shaded.jar /jupyter/lib/access-token-provider.jar
# Copy the Apache Spark SQL connector for Google BigQuery
COPY spark-bigquery-with-dependencies_2.12.jar /jupyter/lib/spark-bigquery-with-dependencies_2.12.jar
# Copy Apache Spark Avro connector
COPY spark-avro_2.12.jar /jupyter/lib/spark-avro_2.12.jar

USER root
# Install pipenv-kernel and delete-pipenv-kernel:
# - Copy in scripts
# - Add aliases
COPY pipenv_kernel.bash /opt/dapla/pipenv_kernel.sh
RUN chmod +x /opt/dapla/pipenv_kernel.sh && \
    echo "alias pipenv-kernel='/opt/dapla/pipenv_kernel.sh'" >> /etc/bash.bashrc

# Virtual environments should be stored in the container, so that they don't fill the 2G storage of the home dir.
ENV WORKON_HOME="/virtualenvs"
RUN mkdir "$WORKON_HOME" && \
    chown -R $NB_UID "$WORKON_HOME"

# Allow notebook user to write (install) new R packages to the library
RUN chown -R $NB_UID "$R_LIBS_USER"

# Image vulnerability scan. If exit code set to 1, fails image build
#COPY --from=aquasec/trivy:latest /usr/local/bin/trivy /usr/local/bin/trivy
#RUN trivy filesystem --ignore-unfixed --exit-code 0 --severity HIGH,CRITICAL /

# Python vuln check, and remove package afterwards
RUN pip install safety
RUN safety check --full-report -i 49913 -i 50463 -i 50664
RUN pip uninstall -y safety && \
    rm -rf /home/jovyan/.cache

#Requirements for gcloud cli
RUN apt update && \
    apt-get -y install apt-transport-https ca-certificates gnupg && \
    apt-get -y clean

#Install gcloud CLI
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && \
    apt-get update -y && \
    apt-get install google-cloud-cli -y && \
    apt-get -y clean


# Copy and run R-script for scanning installed R-packages
# docker build fails if vulnerabilities are found
# https://github.com/tidyverse/haven/issues/681
#COPY scan.R /tmp/
#RUN Rscript /tmp/scan.R

RUN rm -rf /home/jovyan/.cache

# User will not be able to install packages outside of a virtual environment
ENV PIP_REQUIRE_VIRTUALENV=true

USER $NB_UID
