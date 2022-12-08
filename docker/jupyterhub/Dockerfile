# Use latest from https://github.com/jupyterhub/zero-to-jupyterhub-k8s/tree/main/images/hub
FROM jupyterhub/k8s-hub:2.0.0

USER root

# Update distro to apply security fixes
RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get -y remove --auto-remove vim

RUN pip install tokenexchangeauthenticator==0.3.4  && \
    pip install --upgrade jupyterhub-kubespawner

# Set localtime to Europe/Oslo
RUN rm -f /etc/localtime && \
    ln -s /usr/share/zoneinfo/Europe/Oslo /etc/localtime

USER jovyan

# Direct to stdout for Google Cloud Logging
CMD jupyterhub --config /usr/local/etc/jupyterhub/jupyterhub_config.py &>> /dev/stdout
