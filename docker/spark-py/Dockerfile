# This Dockerfile is inspired by
# https://github.com/apache/spark/blob/master/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile

# Use base image that has the same JRE as jupyter/all-spark-notebook
FROM adoptopenjdk/openjdk11:jre-11.0.9.1_1-ubuntu
WORKDIR /

# Reset to root to run installation tasks
USER root

ENV SPARK_HOME /opt/spark

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
    # You may install with python3 packages by using pip3.6
    # Removed the .cache to save space
    apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev wget libbz2-dev curl && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -r /root/.cache && rm -rf /var/cache/apt/*

# Add Tini (not found via apt-get)
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

# Install latest Spark version
RUN wget https://apache.uib.no/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz && \
    tar -zxpf spark-3.1.2-bin-hadoop3.2.tgz -C /tmp && \
    mv /tmp/spark-3.1.2-bin-hadoop3.2 ${SPARK_HOME} && \
    rm -rf /tmp/spark-3.1.2-bin-hadoop3.2 && \
    rm spark-3.1.2-bin-hadoop3.2.tgz
ENV PATH="$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"

# Python 3.8 is not available in the standard Debian 10 repositories, so
# it must be built from source
RUN wget -O Python-3.9.6.tar.xz https://www.python.org/ftp/python/3.9.6/Python-3.9.6.tar.xz && \
    tar -xf Python-3.9.6.tar.xz && \
    rm Python-3.9.6.tar.xz

RUN cd Python-3.9.6 && \
    ./configure --enable-optimizations && \
    make -j 4 && \
    make install && \
    rm -rf Python-3.9.6

COPY entrypoint.sh /opt/
COPY decom.sh /opt/

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh
ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
ARG spark_uid=185
USER ${spark_uid}

