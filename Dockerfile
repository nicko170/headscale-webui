# Global ARG, available to all stages (if renewed)
ARG WORKDIR="/app"
FROM python:3.11-alpine AS builder

# Renew (https://stackoverflow.com/a/53682110):
ARG WORKDIR

# Don't buffer `stdout`:
ENV PYTHONUNBUFFERED=1
# Don't create `.pyc` files:
ENV PYTHONDONTWRITEBYTECODE=1

RUN pip install poetry && poetry config virtualenvs.in-project true

WORKDIR ${WORKDIR}

COPY --chown=1000:1000 . .
RUN poetry install --only main

FROM python:3.11-alpine

ARG WORKDIR
WORKDIR ${WORKDIR}

RUN adduser app -DHh ${WORKDIR} -u 1000
RUN mkdir /app/instance && chown 1000:1000 /app/instance
USER 1000

COPY --chown=app:app --from=builder ${WORKDIR} .

ENV TZ="UTC"
ENV HS_SERVER="http://localhost/"
ENV KEY=""
ENV BASE_PATH="http://127.0.0.1/"

# Authentication variables
ENV AUTH_TYPE="basic"
ENV BASIC_AUTH_USER="user"
ENV BASIC_AUTH_PASS="pass"

# OIDC variables
ENV FLASK_OIDC_PROVIDER_NAME="OIDC"
ENV FLASK_OIDC_CLIENT_ID=Headscale-WebUI
ENV FLASK_OIDC_CLIENT_SECRET=secret
ENV FLASK_OIDC_CONFIG_URL=http://localhost
# ENV FLASK_OIDC_OVERWRITE_REDIRECT_URI=$BASE_PATH
# ENV FLASK_OIDC_REDIRECT_URI=$BASE_PATH"auth"

# Jenkins build args
ARG GIT_COMMIT_ARG=""
ARG GIT_BRANCH_ARG=""
ARG APP_VERSION_ARG=""
ARG BUILD_DATE_ARG=""

ENV GIT_COMMIT=$GIT_COMMIT_ARG
ENV GIT_BRANCH=$GIT_BRANCH_ARG
ENV APP_VERSION=$APP_VERSION_ARG
ENV BUILD_DATE=$BUILD_DATE_ARG

VOLUME /etc/headscale
VOLUME /data

EXPOSE 5000/tcp
ENTRYPOINT ["/app/entrypoint.sh"]z

# Temporarily reduce to 1 worker
CMD gunicorn -w 1 -b 0.0.0.0:5000 server:app