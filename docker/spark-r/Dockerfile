# This Dockerfile is inspired by
# https://github.com/apache/spark/blob/master/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile

# Use base image that has the same JRE as jupyter/all-spark-notebook
ARG java_image_tag=17-jre

FROM eclipse-temurin:${java_image_tag} as prod

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
    apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev wget libbz2-dev curl && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*     # Remove the .cache to save space

# Add Tini (not found via apt-get)
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

# Install latest Spark version
# Install latest Spark version
RUN mkdir -p ${SPARK_HOME} && \
    mkdir -p ${SPARK_HOME}/work-dir && \
    wget -q "https://archive.apache.org/dist/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop${hadoop_version}.tgz" && \
    echo "${spark_checksum} *spark-${spark_version}-bin-hadoop${hadoop_version}.tgz" | sha512sum -c - && \
    tar xzf "spark-${spark_version}-bin-hadoop${hadoop_version}.tgz" -C ${SPARK_HOME} --owner root --group root --no-same-owner && \
    rm "spark-${spark_version}-bin-hadoop${hadoop_version}.tgz"
ENV PATH="$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"

# Install R 4.0.1 (http://cloud.r-project.org/bin/linux/debian/)
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    apt-get update && \
    apt install -y -t jammy-cran40 r-base r-base-dev r-base-core r-recommended && \
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


# Add a second stage for scanning the prod container.
FROM prod AS scan
USER root

RUN apt-get update && \
    apt-get install -y libssl-dev libcurl4-openssl-dev libxml2-dev && \
    rm -rf /var/lib/apt/lists/*

# Add R-library for scanning for vulnerabilities
RUN R -e "install.packages('oysteR', dependencies=TRUE)"

# Copy and run R-script for scanning installed R-packages
# docker build fails if vulnerabilities are found
COPY scan.R /tmp/
RUN trap "Rscript /tmp/scan.R" EXIT
