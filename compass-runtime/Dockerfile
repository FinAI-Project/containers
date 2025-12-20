ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim-bookworm AS builder

ARG APP_USER=compass
ARG APP_DIR=/app

RUN set -e; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential git; \
    useradd --create-home $APP_USER; \
    mkdir -p $APP_DIR; \
    chown -R $APP_USER:$APP_USER $APP_DIR;

ENV VIRTUAL_ENV="$APP_DIR/.venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

USER $APP_USER
WORKDIR $APP_DIR
COPY --chown=$APP_USER:$APP_USER . .
RUN set -e; \
    python -m venv .venv; \
    pip install --no-cache -r requirements.txt --find-links=./packages --extra-index-url=https://pypi.nvidia.com; \
    rm -rf packages;

FROM python:${PYTHON_VERSION}-slim-bookworm

ARG GIT_COMMIT
ARG APP_USER=compass
ARG APP_DIR=/app

ENV TZ=Asia/Singapore
ENV RUNTIME_VERSION="$GIT_COMMIT"
ENV VIRTUAL_ENV="$APP_DIR/.venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN set -e; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends tzdata git make curl rsync; \
    pip cache purge; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone; \
    sh -c "$(curl -sL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    useradd --create-home $APP_USER; \
    mkdir -p $APP_DIR; \
    chown $APP_USER:$APP_USER $APP_DIR; \
    ln -s $APP_DIR/bin/sync-entrypoint.sh /home/$APP_USER/sync-entrypoint.sh; \
    git config --system --add safe.directory '*'

COPY --from=builder $APP_DIR $APP_DIR

USER $APP_USER
WORKDIR $APP_DIR
ENTRYPOINT ["/app/bin/entrypoint.sh"]
