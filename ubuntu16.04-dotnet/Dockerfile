FROM ravensorb/devopsubuntu16.04:${TAG:-latest}

COPY scripts /scripts

ENV AGENT_TOOLSDIRECTORY=/_work/_tool

RUN /scripts/installers/mspackages.sh && \
    /scripts/installers/dotnetcore-sdk.sh && \
    /scripts/installers/powershellcore.sh && \
    /scripts/installers/azpowershell.sh
