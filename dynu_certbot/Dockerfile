FROM python:3.11-alpine

RUN apk add --no-cache \
    bash \
    curl \
    jq \
    bind-tools \
    coreutils \
    && pip install certbot

COPY run.sh /run.sh
COPY dynu-auth.sh /dynu-auth.sh
COPY dynu-cleanup.sh /dynu-cleanup.sh
COPY notify.sh /notify.sh

RUN chmod +x /run.sh /dynu-auth.sh /dynu-cleanup.sh /notify.sh

CMD [ "/run.sh" ]
