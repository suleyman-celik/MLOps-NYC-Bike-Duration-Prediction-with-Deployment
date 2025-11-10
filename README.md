# Project README 

---
## Repository Contents

- Notebooks:
  - `m7-project-durPred.ipynb`
  - `m7-project-model-registry.ipynb`
- `Dockerfile` — base image and packages for the main notebook service.
- `docker-compose.yml` — multi-service runtime (see Services section).

---
## Quick Start

```bash
# From repo root
docker compose up --build
```

**After startup, check these likely URLs:**

- Jupyter Notebook likely on **http://localhost:8888**
- A service mapped to **http://localhost:5001** (often MLflow UI)
- A service mapped to **http://localhost:9000**

---
## Services (from docker-compose.yml)

| Service | Build/Image | Ports | Volumes | Environment |
|---|---|---|---|---|
| `base_notebook` | build: `.` (`Dockerfile`) | `8888:8888`<br>`5001:5001`<br>`9000:9000` | `.:/home/jovyan/work` | `JUPYTER_PORT=8888`<br>`USER_CODE_PATH=/home/jovyan/work/${PROJECT_NAME}`<br>`PROJECT_NAME=mlops` |

> Tip: If a service exposes MLflow, run the UI with `mlflow ui --host 0.0.0.0 --port 5001` inside that container and open http://localhost:5001


---
## Environment & Data Paths

- Review the **Volumes** column to see which host paths are mounted into each container (e.g., a local `./work` folder mapped to `/home/jovyan/work`).
- Put datasets and notebooks into a mounted path so changes persist outside the container.
- Adjust **Environment** variables in `docker-compose.yml` to change ports, tokens, or tracking URIs.

---
## Dockerfile Snapshot

Below is a short excerpt from your `Dockerfile` (first ~60 lines) to document the base image and key dependencies:

```dockerfile
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
```

---
## Typical Workflow

1. **Start the stack**: `docker compose up --build`
2. **Open Jupyter**: use the printed token URL (or one of the hinted ports above).
3. **Run training notebook** (e.g., `m7-project-durPred.ipynb`):
   - Load sample trip data, engineer features, train baseline models.
   - Log metrics/params/artifacts to **MLflow** if configured.
4. **(Optional) Model Registry**: use the `m7-project-model-registry.ipynb` to register and transition model stages.
5. **(Optional) Serving**: serve a model locally with `mlflow models serve ...` and test via cURL or a small client.

---
## Troubleshooting

- **Port already in use**: edit the `ports:` mapping in `docker-compose.yml` (host side) and restart.
- **MLflow UI unreachable**: confirm the container runs on `0.0.0.0:<port>` and that the port is mapped in Compose.
- **File changes not persisting**: ensure your notebooks/data reside in a mounted host directory (see Volumes).
- **Dependency conflicts**: rebuild with `--no-cache` to refresh layers.