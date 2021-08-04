FROM jupyterhub/k8s-hub:0.11.1

USER root

# Update distro to apply security fixes
RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade

RUN pip install tokenexchangeauthenticator==0.0.9

USER jovyan

