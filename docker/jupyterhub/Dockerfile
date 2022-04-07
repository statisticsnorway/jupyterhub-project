# Use latest from https://github.com/jupyterhub/zero-to-jupyterhub-k8s/tree/main/images/hub
FROM jupyterhub/k8s-hub:1.1.3-n404.hb6e0397d

USER root

# Update distro to apply security fixes
RUN apt update && \
    apt-get -y clean all && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade

RUN pip install tokenexchangeauthenticator==0.1.3

# https://github.com/jupyterhub/kubespawner/pull/425
RUN pip install --upgrade git+https://github.com/JJ11teen/kubespawner.git@istio

USER jovyan

