FROM eu.gcr.io/prod-bip/ssb/statistikktjenester/jupyterlab-common:latest

ARG spark_version="3.3.1"
ARG hadoop_version="3"
ARG spark_checksum="769db39a560a95fd88b58ed3e9e7d1e92fb68ee406689fb4d30c033cb5911e05c1942dcc70e5ec4585df84e80aabbc272b9386a208debda89522efff1335c8ff"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy the kernels. (pre-defined kernels are found at /opt/conda/share/jupyter/kernels)
COPY pyspark_k8s /usr/local/share/jupyter/kernels/pyspark_k8s/
COPY pyspark_local /usr/local/share/jupyter/kernels/pyspark_local/
COPY sparkR_k8s/* /opt/conda/share/jupyter/kernels/ir_k8s/
COPY sparkR_local/* /opt/conda/share/jupyter/kernels/ir_spark/
COPY R/* /opt/conda/share/jupyter/kernels/ir/

# Change default R repo
COPY Rprofile.site /etc/R/Rprofile.site

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

COPY ssh-agent-helper.bash /usr/local/bin/ssh-agent-helper.sh
COPY restart-ssh-agent.bash /usr/local/bin/restart-ssh-agent.sh

# Copy the GCS connector.
COPY gcs-connector-shaded.jar /jupyter/lib/gcs-connector-hadoop.jar
# Copy the access token provider for the GCS connector
COPY access-token-provider-shaded.jar /jupyter/lib/access-token-provider.jar
# Copy the Apache Spark SQL connector for Google BigQuery
COPY spark-bigquery-with-dependencies_2.12.jar /jupyter/lib/spark-bigquery-with-dependencies_2.12.jar
# Copy Apache Spark Avro connector
COPY spark-avro_2.12.jar /jupyter/lib/spark-avro_2.12.jar
# Copy Delta Lake libraries
COPY delta-core_2.12.jar /jupyter/lib/delta-core_2.12.jar
COPY delta-storage.jar /jupyter/lib/delta-storage.jar

RUN echo "**** install pipx" && \
    python3 -m pip install --user pipx && \
    python3 -m pipx ensurepath

RUN echo "**** install Dapla CLI tools using pipx" && \
    pipx install \
    ssb-project-cli==1.3.0 \
    dapla-team-cli==0.1.2 && \
    echo "**** install Dapla libraries" && \
    python3 -m pip install \
    dapla-toolbelt==1.8.1 \
    ssb-datadoc==0.3.0 \
    kvakk-git-tools==2.2.1 \
    ssb_spark_tools==0.1.12 && \
    echo "**** install other tools" && \
    python3 -m pip install pandas-gbq pyspark==${APACHE_SPARK_VERSION} google-cloud-storage venv-pack nbdev && \
    python3 -m pip cache purge && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

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

# User will not be able to install packages outside of a virtual environment
ENV PIP_REQUIRE_VIRTUALENV=true
USER $NB_UID
