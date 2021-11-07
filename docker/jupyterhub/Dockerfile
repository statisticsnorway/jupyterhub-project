FROM jupyterhub/k8s-hub:1.2.0

USER root

# Update distro to apply security fixes
RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade

RUN pip install tokenexchangeauthenticator==0.1.3

USER jovyan

