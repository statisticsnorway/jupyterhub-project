# Image contains R and littler
FROM rocker/r-base:4.1.1 AS ssb-r-packages

RUN apt-get update -y \
	&& apt-get install -y --no-install-recommends \
		libglpk-dev \
		libssl-dev \
		libxml2-dev \
	    libcurl4-openssl-dev \
	&& apt autoremove -y \
	&& apt-get -y clean all \
	&& rm -rf /var/lib/apt/lists/*

ENV BASE_PACKAGES renv lattice codetools Matrix MASS stringi magrittr backports jsonlite R6 httr digest rlang \
    htmltools xfun highr evaluate stringr markdown knitr checkmate NLP BH slam tm remotes validate dcmodify rpart \
    simputation lumberjack plotly dash
ENV EXT_PACKAGES tables tidyverse docopt data.table sdcTable SmallCountRounding configr e1071 RTextTools
ENV SSB_PACKAGES SSBtools easySdcTable RegSDC PxWebApiData klassR

RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', dependencies = TRUE, Ncpus = $(nproc))" >> /etc/R/Rprofile.site \
    && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
	&& install.r ${BASE_PACKAGES} ${EXT_PACKAGES} ${SSB_PACKAGES} \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Image contains Spark 3.2.0
# jupyter/all-spark-notebook includes Python, R, and Scala support for Apache Spark.
FROM jupyter/all-spark-notebook:spark-3.2.0 AS ssb-notebook-image

# Install SSH client
USER root

RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get install --no-install-recommends -y openssh-client r-cran-rglpk glpk-utils libglpk-dev libpoppler-cpp-dev \
    zlib1g-dev libgit2-dev libtesseract-dev libleptonica-dev libgdal-dev libjpeg62 r-cran-rjava default-jdk && \
    apt autoremove -y && \
    apt-get -y clean all && \
    rm -rf /var/lib/apt/lists/*

# Copy R libraries from ssb-r-packages container
COPY --from=ssb-r-packages /usr/local/lib/R/site-library /opt/conda/lib/R/library

# Copy R library dependencies from ssb-r-packages container
COPY --from=ssb-r-packages /usr/lib/R/library /opt/conda/lib/R/library

# Fix conda permission
RUN chown -R $NB_UID:$NB_GID /opt/conda

USER $NB_UID

# Install R libraries from conda (the rest is copied from the ssb-r-packages container)
RUN conda update -n base conda && \
    conda install --quiet --yes r-reticulate r-arrow r-devtools r-languageserver r-rgdal r-units \
    r-ggraph r-tidygraph r-nabor && \
    conda clean --all -f -y

# Create a conda env (r-reticulate) that enables R to execute Python code
RUN conda create -y -n r-reticulate python=3.9.7 numpy

# RJDemetra depends on r-rjava 
RUN R CMD javareconf -e && \
    R -e "install.packages('RJDemetra', '/opt/conda/lib/R/library', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "remotes::install_github('r-barnes/dggridR', vignette=TRUE)" && \
    R -e "remotes::install_github('statisticsnorway/Kostra')" && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

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
    echo "**** install pillow==8.3.1 ****" && \
    python3 -m pip install pillow==8.3.1 && \
    echo "**** install jupyterlab-system-monitor ****" && \
    python3 -m pip install jupyterlab-system-monitor && \
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
    python3 -m pip install ssb_spark_tools==0.1.6 pytest pytest_tornasync pytest-cov pytest-mock pyjstat xmltodict lxml holidays PyGithub pre-commit pyminizip && \
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
RUN mkdir /opt/dapla/ && curl --silent -L -o- https://github.com/statisticsnorway/dapla-cli/releases/download/0.1.0/dapla-cli-0.1.0-linux-amd64.tar.gz \
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
    echo "alias pipenv-kernel='/opt/dapla/pipenv_kernel.sh'" >> /etc/bash.bashrc

# Virtual environments should be stored in the container, so that they don't fill the 2G storage of the home dir.
ENV WORKON_HOME="/virtualenvs"
RUN mkdir "$WORKON_HOME" && \
    chown -R $NB_UID "$WORKON_HOME"

USER $NB_UID
