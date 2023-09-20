FROM eu.gcr.io/prod-bip/ssb/statistikktjenester/jupyterlab-common:latest

USER $NB_UID

RUN echo "**** install Dapla CLI tools using pipx" && \
    # Currently this is installed with pip in the common image, remove it so the PATH points to the right one
    python3 -m pip uninstall --yes ssb-project-cli && \
    # Correctly set path for pipx
    export PATH=$(python3 -m site --user-base)/bin:$PATH && \
    pipx install \
    ssb-project-cli==1.3.1 && \
    pipx install \
    dapla-team-cli==0.1.2 && \
    echo "**** install Dapla libraries" && \
    python3 -m pip install \
    dapla-toolbelt==1.8.1 \
    ssb-datadoc==0.3.0 \
    kvakk-git-tools==2.2.1 \
    ssb_spark_tools==0.1.12 \
    echo "**** install other tools" && \
    python3 -m pip install pandas-gbq pyspark==${APACHE_SPARK_VERSION} google-cloud-storage venv-pack nbdev && \
    python3 -m pip cache purge && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Add ~/.local/bin to PATH in .bashrc so its called every time the terminal opens
RUN echo 'export PATH=$(python3 -m site --user-base)/bin:$PATH' >> $HOME/.bashrc

USER root
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

# Allow notebook user to write (install) new R packages to the library
RUN chown -R $NB_UID "$R_LIBS_USER"

# User will not be able to install packages outside of a virtual environment
ENV PIP_REQUIRE_VIRTUALENV=true
USER $NB_UID
