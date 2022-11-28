# This Dockerfile is inspired by
# https://github.com/apache/spark/blob/master/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile
# Use base image that has the same JRE as jupyter/all-spark-notebook
FROM adoptopenjdk/openjdk11:jre-11.0.9.1_1-ubuntu
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
    apt install -y python3 python3-pip && \
    pip3 install --upgrade pip setuptools && \
    pip3 install --upgrade wheel && \
    apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev wget libbz2-dev curl && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -r /root/.cache && rm -rf /var/cache/apt/*     # Remove the .cache to save space

# Add Tini (not found via apt-get)
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

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

RUN cd Python-3.10.4 && \
    ./configure --enable-optimizations && \
    make -j 4 && \
    make install && \
    rm -rf Python-3.10.4

COPY entrypoint.sh /opt/
COPY decom.sh /opt/

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh
ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Default libs
RUN pip3 install numpy
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

