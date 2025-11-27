FROM python:3.13-alpine

ARG APP_USER=app
ARG APP_DIR=/app

RUN set -e; \
    apk update; \
    apk upgrade; \
    apk cache clean; \
    pip install --upgrade pip; \
    pip cache purge; \
    adduser -D -h $APP_DIR $APP_USER;

USER $APP_USER
WORKDIR $APP_DIR
COPY --chown=$APP_USER:$APP_USER *.py requirements.txt .

ENV VIRTUAL_ENV="${APP_DIR}/.venv"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN set -e; \
    python -m venv .venv; \
    pip install --no-cache -r requirements.txt; \
    pip cache purge;

CMD ["python", "main.py"]
