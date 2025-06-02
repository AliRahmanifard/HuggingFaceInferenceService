HuggingFace Inference Service
Dockerized FastAPI-based service for running inference on a HuggingFace model with support for parallel requests.

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Repository Structure](#repository-structure)
4. [Prerequisites](#prerequisites)
5. [Local Development](#local-development)

   * 5.1 [Set Up Virtual Environment](#set-up-virtual-environment)
   * 5.2 [Install Dependencies](#install-dependencies)
   * 5.3 [Run the Server Locally](#run-the-server-locally)
6. [Docker Usage](#docker-usage)

   * 6.1 [Build the Docker Image](#build-the-docker-image)
   * 6.2 [Run the Docker Container](#run-the-docker-container)
   * 6.3 [Using nginx (Optional)](#using-nginx-optional)
7. [Testing Parallel Requests](#testing-parallel-requests)
8. [Model Choice](#model-choice)
9. [Environment Variables](#environment-variables)
10. [Contributing](#contributing)
11. [License](#license)

---

## Overview

This repository implements a simple, scalable inference service for any pretrained HuggingFace model (demo uses a DistilBERT sentiment‐analysis model). The service is built with FastAPI, served by Gunicorn+Uvicorn workers, and containerized with Docker. An optional nginx layer proxies incoming HTTP traffic. A Jupyter notebook demonstrates sending multiple parallel POST requests to the `/predict` endpoint.

---

## Features

* **FastAPI** endpoint for `/predict` accepting JSON `{"text": "<input>"}`
* Loads a HuggingFace model (default: `distilbert-base-uncased-finetuned-sst-2-english`)
* **Gunicorn + Uvicorn workers** for concurrent inference
* **Dockerized** for easy deployment anywhere
* Optional **nginx** reverse proxy for production‐style routing
* Jupyter notebook (`test_parallel_requests.ipynb`) showing parallel requests using `httpx + asyncio`

---

## Repository Structure

```
HuggingFaceInferenceService/
├── Dockerfile
├── README.md
├── requirements.txt
├── server.py
├── start.sh
├── test_parallel_requests.ipynb
├── nginx/
│   └── nginx.conf
└── .gitignore
```

* **Dockerfile**: Builds a Debian‐slim‐based container, installs Python dependencies, nginx, and configures the start‐up script.
* **README.md**: This file—project overview and usage instructions.
* **requirements.txt**: Python dependencies (FastAPI, Uvicorn, Transformers, Torch, Gunicorn).
* **server.py**: FastAPI application that loads the HuggingFace pipeline and exposes `/predict`.
* **start.sh**: Shell script to launch Gunicorn/Uvicorn and nginx side by side in the container.
* **test\_parallel\_requests.ipynb**: Jupyter notebook demonstrating how to send multiple concurrent requests to the server.
* **nginx/nginx.conf**: Sample nginx configuration for proxying requests to the FastAPI app.
* **.gitignore**: Common ignores (e.g., `venv/`, `__pycache__/`, `.ipynb_checkpoints/`).

---

## Prerequisites

1. **Docker Desktop** (Windows/macOS) or Docker Engine (Linux).
2. **Python 3.9+** (for local development)
3. **Git** (to clone this repo)
4. **(Optional) Jupyter Notebook** installed if you want to run `test_parallel_requests.ipynb`.

---

## Local Development

### 5.1 Set Up Virtual Environment

```bash
cd HuggingFaceInferenceService
python3 -m venv venv
source venv/bin/activate       # On Windows: venv\Scripts\activate
```

### 5.2 Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 5.3 Run the Server Locally

You can test the FastAPI app without Docker:

```bash
uvicorn server:app --host 0.0.0.0 --port 8000 --workers 1
```

* The model will download on first run (≈5–10 seconds).
* Once it’s up, send a test request:

  ```bash
  curl -X POST "http://localhost:8000/predict" \
       -H "Content-Type: application/json" \
       -d '{"text":"This service is awesome!"}'
  ```

  Expected response:

  ```json
  {"label":"POSITIVE","score":0.9998}
  ```

---

## Docker Usage

### 6.1 Build the Docker Image

From the project root (where `Dockerfile` lives), run:

```bash
docker build -t hf-sentiment-api:latest .
```

This uses `python:3.9-slim` as a base, installs system packages (nginx), Python dependencies, copies your code, and sets up the start‐up script.

### 6.2 Run the Docker Container

```bash
docker run --rm -d -p 80:80 --name sentiment_service hf-sentiment-api:latest
```

* **`-d`**: Run in detached mode.
* **`-p 80:80`**: Map host port 80 to container’s port 80 (nginx).
* **`--rm`**: Automatically remove the container when it stops.

After a few seconds, nginx + Gunicorn + Uvicorn should be serving the FastAPI app. Test with:

```bash
curl.exe -X POST "http://localhost/predict" \
    -H "Content-Type: application/json" \
    -d '{"text":"Testing the Dockerized service!"}'
```

Expected response:

```json
{"label":"POSITIVE","score":0.9997}
```

### 6.3 Using nginx (Optional)

The provided `nginx/nginx.conf` configures nginx to listen on port 80 and proxy traffic to the FastAPI app on 127.0.0.1:8000. If you prefer to skip nginx and expose port 8000 directly, you can modify `start.sh` and `Dockerfile` accordingly:

1. Remove the `apt-get install nginx` step.
2. Change `CMD` or `start.sh` to run Gunicorn/Uvicorn bound to `0.0.0.0:8000`.
3. Rebuild and then run with:

   ```bash
   docker run --rm -d -p 8000:8000 --name sentiment_service hf-sentiment-api:latest
   ```
4. Test with:

   ```bash
   curl.exe -X POST "http://localhost:8000/predict" \
       -H "Content-Type: application/json" \
       -d '{"text":"No nginx, direct Uvicorn test."}'
   ```

---

## Testing Parallel Requests

A Jupyter notebook (`test_parallel_requests.ipynb`) demonstrates how to drive the API with multiple concurrent requests using `httpx` and `asyncio`:

1. Activate your virtual environment (if not already).
2. Install notebook dependencies (if needed):

   ```bash
   pip install jupyter httpx
   ```
3. Launch Jupyter:

   ```bash
   jupyter notebook
   ```
4. Open `test_parallel_requests.ipynb` and run the cells.

   * The notebook first sends a single test request to verify connectivity.
   * Then it defines an async function that fires off N POSTs in parallel.
   * You’ll see all responses printed, along with total elapsed time. If you used 4 Uvicorn workers, you’ll notice how parallelism shortens overall run time.

---

## Model Choice

I chose **`distilbert-base-uncased-finetuned-sst-2-english`** (DistilBERT fine‐tuned on SST-2 sentiment analysis) for these reasons:

* **Compact & Fast**: DistilBERT is roughly half the size of BERT, making the Docker image lighter (\~250 MB) and inference quick (≤200 ms per request on CPU).
* **Straightforward I/O**: Input is a simple string, output is a JSON label+score, so it’s easy to demonstrate.
* **Common Use Case**: Sentiment analysis is a classic NLP example; reviewers immediately understand.

You can swap in any other HuggingFace model by updating the pipeline call in `server.py`:

```python
classifier = pipeline("sentiment-analysis", model="<your-model-name>")
```

And adjusting your request/response handling if the task differs (e.g., text-generation or zero-shot classification).

---

## Environment Variables

No runtime environment variables are strictly required for this demo. If you want to customize:

* **`MODEL_NAME`**: You could export an environment variable and read it in `server.py` to dynamically load a different model. For example:

  ```python
  import os
  model_name = os.getenv("HF_MODEL_NAME", "distilbert-base-uncased-finetuned-sst-2-english")
  classifier = pipeline("sentiment-analysis", model=model_name)
  ```
* In Docker, you would pass it at `docker run`:

  ```bash
  docker run -e HF_MODEL_NAME="text-generation-model" -p 80:80 hf-sentiment-api:latest
  ```

---

## Contributing

1. Fork the repo and create a branch for your feature/fix.
2. Make changes in a local branch, run tests, and ensure code follows existing style (PEP 8).
3. Push your branch and open a pull request. Describe your changes and why they’re needed.
4. We’ll review, iterate if necessary, then merge into `main`.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

Thank you for using and reviewing this “HuggingFace Inference Service.” If you have any questions, feel free to open an issue or submit a PR!
