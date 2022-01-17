# Image contains Spark 3.2.0
# jupyter/pyspark-notebook includes Python support for Apache Spark and pyarrow library
FROM jupyter/pyspark-notebook:spark-3.2.0 AS ssb-r-packages

USER root

# We will install R and packages using instructions from https://cloud.r-project.org/
# Should be installed into /usr/lib/R/site-library
RUN apt-get update -y \
	&& apt-get install -y --no-install-recommends \
		software-properties-common dirmngr build-essential curl libssl-dev libcurl4-openssl-dev libgdal-dev \
    # add the signing key (by Michael Rutter) for these repos
    # To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
    # Fingerprint: 298A3A825C0D65DFD57CBB651716619E084DAB9
    && wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
        | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc \
    # add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
    && add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" \
    # Get access to 5000+ CRAN Packages
    && add-apt-repository ppa:c2d4u.team/c2d4u4.0+ \
	&& apt autoremove -y \
	&& apt-get -y clean all \
	&& rm -rf /var/lib/apt/lists/*

ENV R_HOME /usr/lib/R
ENV R_LIBS_USER /usr/lib/R/library

RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get -y install --upgrade cryptsetup

FROM ssb-r-packages AS ssb-notebook-image

RUN echo "test in ssb-notebook-image"

FROM ssb-notebook-image

RUN echo "test after from statement"
