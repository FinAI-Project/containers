# https://github.com/albertodonato/query-exporter/blob/main/Dockerfile
ARG PYTHON_VERSION=3.13.9-slim-bookworm
FROM python:${PYTHON_VERSION} AS builder

RUN set -e; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential pkg-config libmariadb-dev-compat; \
    useradd app;

ENV VIRTUAL_ENV="/virtualenv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN set -e; \
    python -m venv $VIRTUAL_ENV; \
    pip install --no-cache query-exporter SQLAlchemy[mysql];

ARG PYTHON_VERSION=3.13.9-slim-bookworm
FROM python:${PYTHON_VERSION}

RUN set -e; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends libmariadb-dev-compat; \
    useradd app; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

ENV VIRTUAL_ENV="/virtualenv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV QE_HOST="0.0.0.0"

USER app
COPY --chown=app:app --from=builder $VIRTUAL_ENV $VIRTUAL_ENV

EXPOSE 9560/tcp
VOLUME /config
WORKDIR /config
ENTRYPOINT ["query-exporter"]
