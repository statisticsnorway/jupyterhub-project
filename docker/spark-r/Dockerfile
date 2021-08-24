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
    apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev wget libbz2-dev curl && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/*

# Add Tini (not found via apt-get)
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

# Install latest Spark version
RUN wget https://apache.uib.no/spark/spark-3.1.2/spark-3.1.2-bin-hadoop2.7.tgz && \
    tar -zxpf spark-3.1.2-bin-hadoop2.7.tgz -C /tmp && \
    mv /tmp/spark-3.1.2-bin-hadoop2.7 ${SPARK_HOME} && \
    rm -rf /tmp/spark-3.1.2-bin-hadoop2.7 && \
    rm spark-3.1.2-bin-hadoop2.7.tgz
ENV PATH="$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"

# Install R 4.0.1 (http://cloud.r-project.org/bin/linux/debian/)
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

RUN \
  echo "deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" >> /etc/apt/sources.list && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
  apt-get update && \
  apt install -y -t focal-cran40 r-base r-base-dev r-base-core r-recommended && \
  rm -rf /var/cache/apt/*

ENV R_HOME /usr/lib/R

COPY entrypoint.sh /opt/
COPY decom.sh /opt/

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh
ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
ARG spark_uid=185
USER ${spark_uid}

