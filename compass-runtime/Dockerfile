ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim-bookworm

ARG GIT_COMMIT
ARG APP_USER=compass
ARG APP_DIR=/app

ENV TZ=Asia/Singapore
ENV RUNTIME_VERSION="$GIT_COMMIT"

RUN set -e; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential tzdata git make cmake curl rsync unzip; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone; \
    curl https://rclone.org/install.sh | bash; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
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
    pip install --no-cache -r requirements.txt; \
    ln -s $APP_DIR/bin/sync-entrypoint.sh /home/$APP_USER/sync-entrypoint.sh; \
    git config --global --add safe.directory '*';

ENTRYPOINT ["/app/bin/entrypoint.sh"]
