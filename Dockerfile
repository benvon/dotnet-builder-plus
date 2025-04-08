ARG DOTNET_IMAGE_VERSION=8.0
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_IMAGE_VERSION} 
ARG AZURE_CLI_VERSION=2.71.0
ARG AZ_DIST=bookworm
ARG AZ_CLI_RELEASE=1
ARG DEBIAN_FRONTEND=noninteractive

# Install basic utilities
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        apt-transport-https=2.6.1 \
        ca-certificates=20230311 \
        curl=7.88.1-10+deb12u12 \
        gnupg=2.2.40-1.1 \
        lsb-release=12.0-1 && \
    rm -rf /var/lib/apt/lists/*

# Install Java
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        default-jre-headless && \
    rm -rf /var/lib/apt/lists/*

# Install additional tools
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        jq=1.6-2.1 \
        nuget && \
    rm -rf /var/lib/apt/lists/*

# Install Azure CLI with minimal footprint
RUN curl --proto "=https" --tlsv1.2 -sSf -L https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y azure-cli=${AZURE_CLI_VERSION}-${AZ_CLI_RELEASE}~${AZ_DIST} && \
    # Clean up unnecessary files
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /opt/az/lib/python3.12/site-packages/azure/cli/command_modules/*/__pycache__ && \
    rm -rf /opt/az/lib/python3.12/site-packages/azure/cli/command_modules/*/*/__pycache__ && \
    find /opt/az -type d -name "__pycache__" -exec rm -r {} + && \
    find /opt/az -type f -name "*.pyc" -delete

# Set environment variables
ENV NUGET_PACKAGES=/packages/.nuget/packages \
    PATH="${PATH}:/packages/.dotnet/tools" \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    NUGET_XMLDOC_MODE=skip

RUN mkdir -p "$NUGET_PACKAGES" && \
    mkdir -p /packages/.dotnet/tools && \
    chmod -R 777 "$NUGET_PACKAGES"
