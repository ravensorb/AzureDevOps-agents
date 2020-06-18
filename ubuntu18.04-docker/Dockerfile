FROM ravensorb/devopsubuntu18.04:${TAG:-latest}

COPY scripts /scripts

RUN /scripts/installers/docker-moby.sh && \
    /scripts/installers/docker-compose.sh && \
    /scripts/installers/kubernetes-tools.sh

