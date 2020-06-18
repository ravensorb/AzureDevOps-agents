FROM ravensorb/devopsubuntu18.04:${TAG:-latest}

COPY scripts /scripts

ENV AGENT_TOOLSDIRECTORY=/_work/_tool

RUN /scripts/installers/nodejs.sh
