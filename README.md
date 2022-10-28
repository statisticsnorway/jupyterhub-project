# Jupyterhub-project
Assembly project for jupyterhub related components

## Checkout sources

```bash
make update-all
```

# Run standalone Jupyterlab

First build the standalone Jupyterlab server:

```bash
cp build/jupyter/*.jar docker/jupyterlab/.
docker build ./docker/jupyterlab -t jupyterlab-user
rm docker/jupyterlab/*.jar
```

Then run the server with mounted volume for gcloud credentials:

```bash
docker run -p 8888:8888 -eGOOGLE_CLOUD_PROJECT=$(gcloud config get project) -v ~/.config/gcloud:/home/jovyan/.config/gcloud jupyterlab-user
```


## Sub projects

* [Jupyterhub extensions](https://github.com/statisticsnorway/jupyterhub-extensions)
* [Jupyterhub GCP](https://github.com/statisticsnorway/jupyterhub-gcp)
* [Dapla Toolbelt](https://github.com/statisticsnorway/dapla-toolbelt)
