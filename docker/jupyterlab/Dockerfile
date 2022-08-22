FROM eu.gcr.io/prod-bip/ssb/statistikktjenester/jupyterlab-common:latest

ARG spark_version="3.2.1"

# Copy the kernels. (pre-defined kernels are found at /opt/conda/share/jupyter/kernels)
COPY pyspark_k8s /usr/local/share/jupyter/kernels/pyspark_k8s/
COPY pyspark_local /usr/local/share/jupyter/kernels/pyspark_local/
COPY sparkR_k8s/kernel.json /opt/conda/share/jupyter/kernels/ir_k8s/
COPY sparkR_k8s/Rstartup /opt/conda/share/jupyter/kernels/ir_k8s/
COPY sparkR_local/kernel.json /opt/conda/share/jupyter/kernels/ir/
COPY sparkR_local/Rstartup /opt/conda/share/jupyter/kernels/ir/

# See https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html#startup-hooks
COPY env.sh /usr/local/bin/before-notebook.d/env.sh
COPY spark-defaults.conf /tmp/spark-defaults.conf

USER root
RUN chown -R $NB_UID /usr/local/share/jupyter/kernels
RUN chown -R $NB_UID /opt/conda/share/jupyter/kernels

USER $NB_UID

# Experimental libraries
# nbdev uses nbconvert 5.6.1
# voila 0.2.7 requires nbconvert<7,>=6.0.0, but you have nbconvert 5.6.1 which is incompatible.
# https://github.com/fastai/nbdev/issues/305
#RUN echo "**** install nbdev ****" && \
# python3 -m pip install nbdev

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
    echo "**** install ipython extensions" && \
    python3 -m pip install dapla-toolbelt==1.3.1 gcsfs==0.6.2 pyspark==${spark_version} pyarrow google-cloud-storage

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
    echo "alias pipenv-kernel='/opt/dapla/pipenv_kernel.sh'" >> /etc/bash.bashrc && \
    echo 'export PIP_INDEX="http://jupyter:$PYPISERVER_PASSWORD@dapla-pypiserver.dapla.svc.cluster.local"' >> /etc/bash.bashrc && \
    echo 'export PIP_INDEX_URL="$PIP_INDEX"' >> /etc/bash.bashrc && \
    echo 'export PIPENV_PYPI_MIRROR="$PIP_INDEX"' >> /etc/bash.bashrc

# Virtual environments should be stored in the container, so that they don't fill the 2G storage of the home dir.
ENV WORKON_HOME="/virtualenvs"
RUN mkdir "$WORKON_HOME" && \
    chown -R $NB_UID "$WORKON_HOME"

# Allow notebook user to write (install) new R packages to the library
RUN chown -R $NB_UID "$R_LIBS_USER"

# Image vulnerability scan. If exit code set to 1, fails image build
#COPY --from=aquasec/trivy:latest /usr/local/bin/trivy /usr/local/bin/trivy
#RUN trivy filesystem --ignore-unfixed --exit-code 0 --severity HIGH,CRITICAL /

# Python vulnerability scan
RUN pip install safety
RUN safety check --full-report

# Copy and run R-script for scanning installed R-packages
# docker build fails if vulnerabilities are found
# https://github.com/tidyverse/haven/issues/681
#COPY scan.R /tmp/
#RUN Rscript /tmp/scan.R

RUN rm -rf /home/jovyan/.cache

USER $NB_UID
