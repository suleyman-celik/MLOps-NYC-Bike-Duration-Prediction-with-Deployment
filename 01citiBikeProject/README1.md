# MLOps Notebook Project — Ride Duration Prediction + MLflow (Dockerized)

This repository contains a **Dockerized Jupyter development environment** and two notebooks that walk through a small MLOps workflow for **ride duration prediction** using open mobility datasets (NYC TLC Taxi and Citi Bike as examples) and **MLflow** for experiment tracking and model registry.

> TL;DR — Run Jupyter with Docker Compose, open the notebooks, train a model, and track experiments locally with MLflow (SQLite).

---

## What’s inside?

- **`m7-project-durPred.ipynb`** — end‑to‑end notebook:
  - Data download/prep (examples include NYC **Taxi** & **Citi Bike** trip data)
  - Feature engineering (categorical: `rideable_type`, `member_casual`, `start_station_id`, `end_station_id`; numeric: start/end latitude & longitude; time‑based features, etc.)
  - Baseline models (linear models) and tree‑based baselines
  - Evaluation with **RMSE**
  - Local **MLflow** tracking (default: `sqlite:///mlflow.db`)

- **`m7-project-model-registry.ipynb`** — **MLflow Model Registry** demo:
  - Create/connect to a tracking server
  - Register a model (e.g., `nyc-taxi-regressor`) and new versions
  - Transition versions across **Staging/Production** and annotate runs

- **`Dockerfile`** — builds a Jupyter image (based on `jupyter/base-notebook`), installing common data/ML packages (e.g., pandas, scikit‑learn, matplotlib, seaborn, scipy, ipywidgets, pyarrow, openpyxl, joblib).  
  Exposes Jupyter and convenience ports.

- **`docker-compose.yml`** — runs one or more Jupyter notebook services:
  - `base_notebook` (Python): **ports 8888**, **5001**, **9000**
  - `r_notebook` (optional R stack): **port 8889** (requires an `r-notebook` Docker context)
  - Named networks for clean separation (`back_tier`, `front_tier`, `jupyter_network`, `r_network`)

> Heads‑up: The compose file builds `base_notebook` from `Dockerfile`. The `r_notebook` service expects `jupyter.Dockerfile` targeting `jupyter/r-notebook`. If you don’t have a separate file, either **copy `Dockerfile` to `jupyter.Dockerfile`** and change `BASE_IMAGE=jupyter/r-notebook:latest`, or **remove** the `r_notebook` service from Compose.

---

## Quick Start

### 1) Prerequisites
- **Docker** (and **Docker Compose**)
- ~4–6 GB free disk for datasets and conda env

### 2) Build & Run
```bash
# From the repository root
docker compose up --build
# or if your Docker version uses the old plugin:
# docker-compose up --build
```

- Open the Jupyter URL printed in the logs (token included), typically:
  - Python notebook: <http://localhost:8888>
  - (Optional) R notebook: <http://localhost:8889>

### 3) Notebooks to run
- Open **`m7-project-durPred.ipynb`** and run top‑to‑bottom
  - It includes commands to download a small sample of **NYC Taxi**/**Citi Bike** data
  - It filters, engineers features, trains baselines, and logs to **MLflow**
- Open **`m7-project-model-registry.ipynb`** to learn how to:
  - Query runs (e.g., filter by `metrics.rmse`)
  - **Register** a model and **transition** its stages

---

## MLflow Tracking & UI

The training notebook configures MLflow with a local SQLite backend (example):
```python
mlflow.set_tracking_uri("sqlite:///mlflow.db")
```

To inspect experiments visually, you can run the MLflow UI from **inside** the Jupyter container shell:

```bash
# inside the running container for base_notebook
mlflow ui --backend-store-uri sqlite:///mlflow.db --host 0.0.0.0 --port 5001
```

Then open: <http://localhost:5001>

> The docker compose already maps **5001:5001**, so the UI will be available from your host.  
> Port **9000** is mapped as well and can be repurposed for an artifact store like MinIO if you extend the stack.

---

## Project Structure

```
.
├── Dockerfile
├── docker-compose.yml
├── m7-project-durPred.ipynb
└── m7-project-model-registry.ipynb
```

- **Notebooks** live under the container workdir: `/home/jovyan/work/`
- Environment variables in Compose:
  - `JUPYTER_PORT` (default 8888 for Python service, 8889 for R service)
  - `PROJECT_NAME=mlops`
  - `USER_CODE_PATH=/home/jovyan/work/${PROJECT_NAME}` (optional convenience var)

---

## Data Notes

- The notebooks use public sample datasets (NYC TLC Taxi & Citi Bike) and demonstrate:
  - **Downloading** raw files (CSV/Parquet/ZIP)
  - **Extracting** and **filtering** trips by duration (e.g., 1–40 min window)
  - **Feature engineering** for station/zone IDs and coordinates
- You can replace the data with your own source while keeping the same modeling pattern.

**Typical features in the examples:**
- Categorical: `rideable_type`, `member_casual`, `start_station_id`, `end_station_id`  
- Numerical: `start_lat`, `start_lng`, `end_lat`, `end_lng`  
- Target: **trip duration** in minutes  
- Metric: **RMSE**

---

## Extending the Stack

- **Artifacts/Registry**:
  - Switch the MLflow tracking URI to a remote server (or add MinIO/S3 for artifact storage)
  - Use the **Model Registry** notebook to manage versions and stages
- **Serving**:
  - Try `mlflow models serve -m <model_uri> -p 5002 --host 0.0.0.0` for quick local inference
- **Pipelines**:
  - Extract the data prep and training code from the notebook into Python modules and schedule them (e.g., with GitHub Actions or Airflow)


---

## Troubleshooting

- **Jupyter token / cannot open 8888**: check container logs and verify the mapped port isn’t in use.  
- **MLflow UI doesn’t load**: ensure the UI is running in the container on `0.0.0.0:5001`.  
- **R notebook build fails**: either remove `r_notebook` from Compose or provide a `jupyter.Dockerfile` with `BASE_IMAGE=jupyter/r-notebook:latest`.  
- **Pip/conda conflicts**: the base image uses conda/mamba; prefer installing most packages via `mamba` in the Dockerfile.

---

## License

This project is for educational purposes. Use at your own discretion for demos and experiments.
