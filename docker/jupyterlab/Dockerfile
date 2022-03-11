# Image contains Spark 3.x
# jupyter/pyspark-notebook includes Python support for Apache Spark and pyarrow library
FROM jupyter/pyspark-notebook:spark-3.2.1 AS ssb-r-packages

# Must match https://github.com/jupyter/docker-stacks/blob/master/pyspark-notebook/Dockerfile#L20
ARG openjdk_version="11"
USER root

# We will install R and packages using instructions from https://cloud.r-project.org/
# Should be installed into /usr/lib/R/site-library
RUN apt-get update -y \
	&& apt-get install -y --no-install-recommends "openjdk-${openjdk_version}-jdk-headless" \
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

COPY r-packages.txt /tmp/r-packages.txt
COPY jwsacruncher-2.2.4.zip /tmp/jwsacruncher-2.2.4.zip

RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    xargs apt-get install -y --no-install-recommends < /tmp/r-packages.txt && \
    apt autoremove -y && \
    apt-get -y clean all && \
    rm -rf /var/lib/apt/lists/*

# Setup R java support and install R packages that are not available as Ubuntu packages
RUN R CMD javareconf -e && \
    R -e "install.packages('RTextTools', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('configr', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('RegSDC', dependencies=FALSE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('oysteR', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('writexl', dependencies=FALSE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('concaveman', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('cppRouting', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('rjwsacruncher', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('klassR', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('antiword', dependencies=FALSE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('textshape', dependencies=FALSE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('striprtf', dependencies=FALSE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('textreadr', dependencies=FALSE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('terra', dependencies=FALSE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('raster', dependencies=FALSE, repos='http://cran.rstudio.com/')" && \
    R -e "install.packages('leaflet', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    # Doesn t work with Java11 - use a custom one
    #curl --silent -L -o- https://github.com/jdemetra/jwsacruncher/releases/download/v2.2.3/jwsacruncher-2.2.3-bin.zip | bsdtar -xvf- -C /opt && \
    unzip /tmp/jwsacruncher-2.2.4.zip -d /opt && fix-permissions /opt/jwsacruncher-2.2.4 && rm -f /tmp/jwsacruncher-2.2.4.zip

RUN R -e "remotes::install_github('r-barnes/dggridR', vignette=TRUE)" && \
    R -e "remotes::install_github('statisticsnorway/Kostra')" && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

FROM ssb-r-packages AS ssb-notebook-image

USER $NB_UID

RUN echo "**** install jupyterlab-git ****" && \
    python3 -m pip install --upgrade jupyterlab-git && \
    echo "**** install nbdime ****" && \
    python3 -m pip install --upgrade nbdime && \
    jupyter labextension install --no-build nbdime-jupyterlab && \
    echo "**** install nbstripout ****" && \
    python3 -m pip install nbstripout && \
    echo "**** install papermill ****" && \
    python3 -m pip install papermill && \
    echo "**** install ipywidgets ****" && \
    python3 -m pip install ipywidgets && \
    echo "**** install jupyter_server_proxy ****" && \
    python3 -m pip install jupyter-server-proxy && \
    echo "**** install holoviz panel ****" && \
    python3 -m pip install --upgrade pyviz_comms && \
    echo "**** install Voilà ****" && \
    python3 -m pip install voila && \
    echo "**** install Plotly ****" && \
    # JupyterLab renderer support
    python3 -m pip install plotly && \
    echo "**** install geopandas ****" && \
    python3 -m pip install geopandas && \
    echo "**** install ipyleaflet ****" && \
    python3 -m pip install ipyleaflet && \
    echo "**** install descartes ****" && \
    python3 -m pip install descartes && \
    echo "**** install dash ****" && \
    python3 -m pip install jupyter-dash && \
    #echo "**** install streamlit ****" && \
    #showstopper: https://github.com/streamlit/streamlit/issues/2703
    #python3 -m pip install streamlit && \
    echo "**** install jupyter-lsp ****" && \
    python3 -m pip install jupyterlab-lsp && \
    python3 -m pip install python-language-server[all] && \
    echo "**** install ipysheet ****" && \
    python3 -m pip install ipysheet && \
    echo "**** install ipyaggrid ****" && \
    python3 -m pip install ipyaggrid && \
    #echo "**** install qgrid ****" && \
    #showstopper: https://github.com/quantopian/qgrid/issues/350
    #python3 -m pip install qgrid2 && \
    echo "**** install fuzzywuzzy[speedup] ****" && \
    python3 -m pip install fuzzywuzzy[speedup] && \
    echo "**** install jupyterlab-system-monitor ****" && \
    python3 -m pip install jupyterlab-system-monitor && \
    echo "**** install jupytext ****" && \
    python3 -m pip install jupytext && \
    #jupyter labextension install --no-build jupyterlab-jupytext && \
    echo "**** uninstall IPython Parallels (comes default with dockerhub image)  ****" && \
    python3 -m pip uninstall -y ipyparallel && \
    python3 -m pip cache purge && \
    rm -rf /home/jovyan/.cache && \
    conda clean --all -y && \
    jupyter lab clean

FROM ssb-notebook-image

RUN jupyter lab build --dev-build=False && \
    python3 -m pip install --upgrade jupyterhub && \
    jupyterhub upgrade-db

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
# Add extra config to jupyter_notebook_config.py
COPY jupyter_notebook_extra_config.py /tmp/
RUN cat /tmp/jupyter_notebook_extra_config.py >> /etc/jupyter/jupyter_notebook_config.py && \
    rm -f /tmp/jupyter_notebook_extra_config.py && \
    fix-permissions /usr/local/spark/conf

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
    python3 -m pip install ssb_spark_tools==0.1.6 pytest pytest_tornasync pytest-cov pytest-mock pyjstat xmltodict lxml holidays PyGithub pre-commit pyminizip rich openpyxl && \
    echo "**** install sphinx ****" && \
    python3 -m pip install sphinx sphinx-autodoc-defaultargs sphinx-autodoc-typehints sphinx-rtd-theme && \
    echo "**** install pandas-gbq and correponding google (auth/cloud/bigquery) dependencies " && \
    python3 -m pip install pandas-gbq && \
    echo "**** install collapsible headers (for Jupyterlab >= 3.0) ****" && \
    python3 -m pip install aquirdturtle_collapsible_headings && \
    echo "**** install ipython extensions" && \
    python3 -m pip install ssb-ipython-kernels==0.3.3 gcsfs==0.6.2 pyspark pyarrow

COPY configure-git-config.bash /usr/local/bin/configure-git-config.bash
COPY configure-git-ssh-config.bash /usr/local/bin/configure-git-ssh-config.bash
COPY git-config.bash /usr/local/bin/git-config.sh
COPY ssh-agent-helper.bash /usr/local/bin/ssh-agent-helper.sh
COPY restart-ssh-agent.bash /usr/local/bin/restart-ssh-agent.sh

COPY check-git-config.bash /usr/local/bin/check-git-config.sh

# Copy the GCS connector.
COPY gcs-connector-shaded.jar /jupyter/lib/gcs-connector-hadoop.jar
# Copy the access token provider for the GCS connector
COPY access-token-provider-shaded.jar /jupyter/lib/access-token-provider.jar
# Copy the Apache Spark SQL connector for Google BigQuery
COPY spark-bigquery-with-dependencies_2.12.jar /jupyter/lib/spark-bigquery-with-dependencies_2.12.jar

# Install dapla cli:
# - Install bash-completion
# - Download latest release from github.
# - Setup autocompletion
# - Add aliases
# - Install jq, which is needed for the former
USER root
RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get install -y --no-install-recommends \
        bash-completion jq iputils-ping traceroute && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir /opt/dapla/ && curl --silent -L -o- https://github.com/statisticsnorway/dapla-cli/releases/download/0.1.2/dapla-cli-0.1.2-linux-amd64.tar.gz \
   | tar xvz -C /opt/dapla
RUN chmod +x /opt/dapla/dapla-cli
COPY dapla-cli.yml /opt/dapla/.dapla-cli.yml
RUN /opt/dapla/dapla-cli completion bash > /etc/bash_completion.d/dapla && \
    echo "alias dapla='/opt/dapla/dapla-cli --config /opt/dapla/.dapla-cli.yml'" >> /etc/bash.bashrc && \
    echo "alias lsd='dapla ls'" >> /etc/bash.bashrc && \
    echo "alias rmd='dapla rm'" >> /etc/bash.bashrc

# Install pipenv-kernel and delete-pipenv-kernel:
# - Copy in scripts
# - Add aliases
COPY pipenv_kernel.bash /opt/dapla/pipenv_kernel.sh
RUN chmod +x /opt/dapla/pipenv_kernel.sh && \
    echo "alias pipenv-kernel='/opt/dapla/pipenv_kernel.sh'" >> /etc/bash.bashrc && \
    echo 'export PIP_INDEX="https://jupyter:$PYPISERVER_PASSWORD@dapla-pypiserver-39.$CLUSTER_ID.ssb.no"' >> /etc/bash.bashrc && \
    echo 'export PIP_INDEX_URL="$PIP_INDEX"' >> /etc/bash.bashrc && \
    echo 'export PIPENV_PYPI_MIRROR="$PIP_INDEX"' >> /etc/bash.bashrc

# Virtual environments should be stored in the container, so that they don't fill the 2G storage of the home dir.
ENV WORKON_HOME="/virtualenvs"
RUN mkdir "$WORKON_HOME" && \
    chown -R $NB_UID "$WORKON_HOME"

# Allow notebook user to write (install) new R packages to the library
RUN chown -R $NB_UID "$R_LIBS_USER"

# Image vulnerability scan. If exit code set to 1, fails image build
COPY --from=aquasec/trivy:latest /usr/local/bin/trivy /usr/local/bin/trivy
RUN trivy filesystem --ignore-unfixed --exit-code 0 --severity HIGH,CRITICAL /

# Python vulnerability scan
RUN pip install safety
RUN trap "safety check --json -o safety_results.json" EXIT
RUN echo safety_results.json

# Copy and run R-script for scanning installed R-packages
# docker build fails if vulnerabilities are found
COPY scan.R /tmp/
RUN Rscript /tmp/scan.R

RUN rm -rf /home/jovyan/.cache

USER $NB_UID
