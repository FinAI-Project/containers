ARG PYTHON_VERSION=3.13
FROM python:${PYTHON_VERSION}-alpine AS builder

ARG VERSION=3.5.0
ARG APP_USER=mlflow
ARG APP_DIR=/app

RUN set -e; \
    apk update; \
    apk add --virtual .build-deps build-base; \
    adduser -D -h $APP_DIR $APP_USER;

ENV VIRTUAL_ENV="$APP_DIR/.venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

USER $APP_USER
WORKDIR $APP_DIR
RUN set -e; \
    python -m venv .venv; \
    pip install --no-cache mlflow==$VERSION psycopg2-binary azure-identity azure-storage-blob;

ARG PYTHON_VERSION=3.13
FROM python:${PYTHON_VERSION}-alpine

ARG APP_USER=mlflow
ARG APP_DIR=/app

RUN set -e; \
    apk update; \
    apk upgrade; \
    apk cache clean; \
    pip install --upgrade pip; \
    pip cache purge; \
    adduser -D -h $APP_DIR $APP_USER;

ENV VIRTUAL_ENV="${APP_DIR}/.venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV MLFLOW_HOST="0.0.0.0"
ENV MLFLOW_PORT="5000"

USER $APP_USER
WORKDIR $APP_DIR
COPY --chown=$APP_USER:$APP_USER --from=builder $APP_DIR $APP_DIR

CMD ["mlflow", "server"]