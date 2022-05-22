# Use latest from https://github.com/jupyterhub/zero-to-jupyterhub-k8s/tree/main/images/hub
FROM jupyterhub/k8s-hub:1.2.0

USER root

# Update distro to apply security fixes
RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade

RUN pip install --upgrade git+https://github.com/statisticsnorway/jupyterhub-extensions.git@feature/force-refresh#subdirectory=TokenExchangeAuthenticator  && \
    pip install --upgrade jupyterhub-kubespawner

USER jovyan

