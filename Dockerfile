FROM python:3.14-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV UV_VERSION="0.10.4"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cargo \
    pkg-config \
    python3-dev \
    rustc \
  && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --no-cache-dir "uv==${UV_VERSION}"

WORKDIR /app

# Sync deps first for better caching.
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY . .

FROM python:3.14-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app /app

ENV PATH="/app/.venv/bin:${PATH}"

EXPOSE 8082

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8082"]
