# This Dockerfile is inspired by
# https://github.com/apache/spark/blob/master/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile

# Use base image that has the same JRE as jupyter/all-spark-notebook
FROM eclipse-temurin:11-jre-focal AS prod

WORKDIR /

# Reset to root to run installation tasks
USER root

ENV SPARK_HOME /opt/spark
ARG spark_version="3.2.1"

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
RUN wget https://archive.apache.org/dist/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop3.2.tgz && \
    tar -zxpf spark-${spark_version}-bin-hadoop3.2.tgz -C /tmp && \
    mv /tmp/spark-${spark_version}-bin-hadoop3.2 ${SPARK_HOME} && \
    rm -rf /tmp/spark-${spark_version}-bin-hadoop3.2 && \
    rm spark-${spark_version}-bin-hadoop3.2.tgz
ENV PATH="$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"

# Python 3.x is not available in the standard Debian 10 repositories, so
# it must be built from source
RUN wget -O Python-3.10.4.tar.xz https://www.python.org/ftp/python/3.10.4/Python-3.10.4.tar.xz && \
    tar -xf Python-3.10.4.tar.xz && \
    rm Python-3.10.4.tar.xz

# Make a symlink to /opt/conda/bin/python3 to mirror python location on jupyterlab
RUN cd Python-3.10.4 && \
    ./configure --enable-optimizations && \
    make -j 4 && \
    make install && \
    mkdir -p /opt/conda/bin && \
    ln -s /usr/local/bin/python3 /opt/conda/bin/python3 && \
    rm -rf Python-3.10.4

COPY entrypoint.sh /opt/
COPY decom.sh /opt/

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh
ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Default libs
RUN pip3 install --upgrade pip numpy pandas wheel>=0.38.1
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

