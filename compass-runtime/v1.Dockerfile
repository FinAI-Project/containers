ARG PYTHON_VERSION=3.10
FROM python:${PYTHON_VERSION}-slim-bookworm

ARG GIT_COMMIT
ARG APP_USER=compass
ARG APP_DIR=/app

ENV TZ=Asia/Singapore
ENV RUNTIME_VERSION="${GIT_COMMIT}"
ENV DEBIAN_FRONTEND=noninteractive

RUN set -e; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential tzdata git make curl rsync unzip; \
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    curl -fsSL "https://downloads.rclone.org/rclone-current-linux-amd64.zip" -o /tmp/rclone.zip; \
    unzip /tmp/rclone.zip -d /tmp; \
    install -m 755 /tmp/rclone-*-linux-amd64/rclone /usr/local/bin/rclone; \
    rm -rf /tmp/rclone*; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    useradd --create-home "${APP_USER}"; \
    mkdir -p "${APP_DIR}" /data /output; \
    chown -R "${APP_USER}:${APP_USER}" "${APP_DIR}" /data /output;

ENV JOB_MODEL_VERSION="v4"
ENV VIRTUAL_ENV="${APP_DIR}/.venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

USER ${APP_USER}
WORKDIR ${APP_DIR}
COPY --chown=${APP_USER}:${APP_USER} . .
RUN set -e; \
    python -m venv .venv; \
    pip install --no-cache -r requirements-v1.txt; \
    git config --global credential.helper '/app/bin/git-credential-helper.py'; \
    git config --global --add safe.directory /app/code;

CMD ["/app/bin/start.sh"]