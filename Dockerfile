ARG DOTNET_IMAGE_VERSION=8.0
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_IMAGE_VERSION} AS final
ARG AZURE_CLI_VERSION=2.71.0
ARG AZ_DIST=bookworm
ARG AZ_CLI_RELEASE=1
ARG DEBIAN_FRONTEND=noninteractive

# Install Azure CLI and dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        apt-transport-https=2.6.1 \
        ca-certificates=20230311 \
        curl=7.88.1-10+deb12u12 \
        default-jdk \
        gnupg=2.2.40-1.1 \
        jq=1.6-2.1 \
        lsb-release=12.0-1 \
        nuget && \
    # Install Azure CLI
    curl --proto "=https" --tlsv1.2 -sSf -L https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y azure-cli=${AZURE_CLI_VERSION}-${AZ_CLI_RELEASE}~${AZ_DIST} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# Set environment variables
ENV NUGET_PACKAGES=/packages/.nuget/packages \
    PATH="${PATH}:/packages/.dotnet/tools" \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    NUGET_XMLDOC_MODE=skip

RUN mkdir -p "$NUGET_PACKAGES" && \
    mkdir -p /packages/.dotnet/tools && \
    chmod -R 777 "$NUGET_PACKAGES"
