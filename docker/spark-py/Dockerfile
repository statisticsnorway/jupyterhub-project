# This Dockerfile is inspired by
# https://github.com/apache/spark/blob/master/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile

# Use base image that has the same JRE as jupyter/all-spark-notebook
ARG java_image_tag=17-jre

FROM eclipse-temurin:${java_image_tag}

WORKDIR /

# Reset to root to run installation tasks
USER root

ENV SPARK_HOME /opt/spark
ARG spark_version="3.3.1"
ARG hadoop_version="3"
ARG spark_checksum="769db39a560a95fd88b58ed3e9e7d1e92fb68ee406689fb4d30c033cb5911e05c1942dcc70e5ec4585df84e80aabbc272b9386a208debda89522efff1335c8ff"

RUN set -ex && \
    sed -i 's/http:\/\/deb.\(.*\)/https:\/\/deb.\1/g' /etc/apt/sources.list && \
    ln -s /lib /lib64 && \
    apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev tini procps net-tools python3-pip \
    libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev wget libbz2-dev curl && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*     # Remove the .cache to save space

# Install latest Spark version
RUN wget https://archive.apache.org/dist/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop${hadoop_version}.tgz && \
     tar -zxpf spark-${spark_version}-bin-hadoop${hadoop_version}.tgz -C /tmp && \
     mv /tmp/spark-${spark_version}-bin-hadoop${hadoop_version} ${SPARK_HOME} && \
     rm -rf /tmp/spark-${spark_version}-bin-hadoop${hadoop_version} && \
     rm spark-${spark_version}-bin-hadoop${hadoop_version}.tgz
ENV PATH="$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"

# Python 3.x is not available in the standard Debian 10 repositories, so
# it must be built from source
RUN wget -O Python-3.10.8.tar.xz https://www.python.org/ftp/python/3.10.8/Python-3.10.8.tar.xz && \
    tar -xf Python-3.10.8.tar.xz && \
    rm Python-3.10.8.tar.xz

# Make a symlink to /opt/conda/bin/python3 to mirror python location on jupyterlab
RUN cd Python-3.10.8 && \
    ./configure --enable-optimizations && \
    make -j 4 && \
    make install && \
    mkdir -p /opt/conda/bin && \
    ln -s /usr/local/bin/python3 /opt/conda/bin/python3 && \
    rm -rf Python-3.10.8

# Cppy executables from Spark source
RUN wget -O /opt/entrypoint.sh https://raw.githubusercontent.com/apache/spark/v${spark_version}/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/entrypoint.sh && \
    wget -O /opt/decom.sh https://raw.githubusercontent.com/apache/spark/v${spark_version}/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/decom.sh

WORKDIR ${SPARK_HOME}/work-dir
RUN chmod g+w ${SPARK_HOME}/work-dir && \
    chmod a+x /opt/decom.sh && \
    chmod a+x /opt/entrypoint.sh
ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Default libs
RUN pip3 install --upgrade pip wheel>=0.38.1 setuptools>=65.5.1 numpy pandas pyarrow
# Python vuln check, and remove package afterwards
RUN pip install safety
RUN safety check --full-report
RUN pip uninstall -y safety && \
    pip cache purge

# Filesystem vuln check of image/os, and remove package after
COPY --from=aquasec/trivy:latest /usr/local/bin/trivy /usr/local/bin/trivy
RUN trivy filesystem --ignore-unfixed --exit-code 0 --severity HIGH,CRITICAL / && \
    rm -rf /usr/local/bin/trivy

# Specify the User that the actual main process will run as
ARG spark_uid=185
USER ${spark_uid}

