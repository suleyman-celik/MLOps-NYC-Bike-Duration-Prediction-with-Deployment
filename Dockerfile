## jupyter.Dockerfile
## https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#image-relationships
## https://github.com/jupyter/docker-stacks/blob/main/images/base-notebook/Dockerfile#L58

## Use the official Jupyter Docker Stacks
## "jupyter/base-notebook:latest"
## "jupyter/minimal-notebook:latest"
## "jupyter/scipy-notebook:latest"
## "jupyter/r-notebook:latest"
## "jupyter/tensorflow-notebook:latest"
## "jupyter/pytorch-notebook:latest"
## "jupyter/pyspark-notebook:latest"

## Define the build argument with a default value
ARG BASE_IMAGE=jupyter/base-notebook:latest

## Use the argument to specify the base image
FROM ${BASE_IMAGE}

## Set environment variable with default port
## overriding if JUPYTER_PORT is already set
ENV JUPYTER_PORT=${JUPYTER_PORT:-8888}

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root
## Time Zone Error
# RUN sed -i '/jammy-updates/s/^/#/' /etc/apt/sources.list \
#     && sed -i '/jammy-security/s/^/#/' /etc/apt/sources.list
## Install all OS dependencies
RUN apt-get update --yes \
    && apt-get install --yes --no-install-recommends --allow-downgrades \
        ## Common useful utilities
        git \
        git-lfs \
        wget \
        curl \
        make \
        gcc \
        unzip \
        gzip \
        bzip2 \
        p7zip-full \
        p7zip-rar \
        unrar \
        tar \
        graphviz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


## Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
## Optionally, Additional configurations or installations (if needed)
RUN mamba install --yes \
        'pandas' \
        'xlrd' \
        'openpyxl' \
        'pyarrow' \
        'joblib' \
        'matplotlib-base' \
        'ipympl'\
        'ipywidgets' \
        'widgetsnbextension'\
        'seaborn' \
        'scipy<=1.12' \
        'statsmodels' \
        'scikit-learn' \
        'scikit-plot' \
        'mlflow' \
        'xgboost' \
        'optuna' \
        'hyperopt' \
        'h5py' \
        'jupyterlab-git' \
    && mamba clean --all -f -y \
    && fix-permissions "${CONDA_DIR}" \
    && fix-permissions "/home/${NB_USER}"

## Expose the Jupyter notebook port
## Default value is 8888, can be overridden
EXPOSE ${JUPYTER_PORT:-8888}  
EXPOSE 8888-8890
EXPOSE 5000-5002
EXPOSE 9000-9002

## Set the command to start Jupyter lab with the specified port
CMD start-notebook.py --port ${JUPYTER_PORT}

## Set working directory (if needed)
WORKDIR "${HOME}/work"