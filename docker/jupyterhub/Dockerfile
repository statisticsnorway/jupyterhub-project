FROM jupyterhub/jupyterhub:2.2.2

USER root

# Update distro to apply security fixes
RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade

RUN pip install tokenexchangeauthenticator==0.2.1  && \
    pip install --upgrade jupyterhub-kubespawner

USER jovyan

