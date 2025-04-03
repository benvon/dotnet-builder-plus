ARG DOTNET_IMAGE_VERSION=8.0
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_IMAGE_VERSION} AS builder

# Set environment variables
ENV NUGET_PACKAGES=/root/.nuget/packages \
    PATH="${PATH}:/root/.dotnet/tools" \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    NUGET_XMLDOC_MODE=skip

# Install global tools
RUN dotnet tool install -g dotnet-ef --version "8.0.*" && \
    dotnet tool install -g dotnet-sonarscanner --version "5.*" && \
    dotnet tool install -g dotnet-reportgenerator-globaltool --version "5.*" && \
    dotnet tool install -g dotnet-outdated-tool --version "3.*" && \
    echo 'export PATH="$PATH:/root/.dotnet/tools"' > /etc/profile.d/dotnet-tools.sh && \
    chmod +x /etc/profile.d/dotnet-tools.sh

# Create warmup project with common packages
RUN DOTNET_LATEST=$(dotnet --version) && \
    echo "Using .NET SDK version: $DOTNET_LATEST" && \
    dotnet new console --no-restore -n warmup && \
    cd warmup && \
    dotnet new globaljson --sdk-version "$DOTNET_LATEST" && \
    # Core packages
    dotnet add package Microsoft.Extensions.Configuration --version "8.*" && \
    dotnet add package Microsoft.Extensions.DependencyInjection --version "8.*" && \
    dotnet add package Microsoft.Extensions.Logging --version "8.*" && \
    # Entity Framework packages
    dotnet add package Microsoft.EntityFrameworkCore --version "8.*" && \
    dotnet add package Microsoft.EntityFrameworkCore.Design --version "8.*" && \
    dotnet add package Microsoft.EntityFrameworkCore.SqlServer --version "8.*" && \
    dotnet add package Microsoft.EntityFrameworkCore.Tools --version "8.*" && \
    dotnet add package Pomelo.EntityFrameworkCore.MySql --version "8.*" && \
    # Azure packages
    dotnet add package Microsoft.Azure.WebJobs --version "3.*" && \
    dotnet add package Microsoft.Azure.WebJobs.Extensions --version "5.*" && \
    dotnet add package Microsoft.Azure.Functions.Worker --version "1.*" && \
    dotnet add package Microsoft.Azure.Functions.Worker.Sdk --version "1.*" && \
    # Security packages
    dotnet add package Microsoft.IdentityModel.Tokens --version "7.*" && \
    dotnet add package System.IdentityModel.Tokens.Jwt --version "7.*" && \
    dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer --version "8.*" && \
    # Testing packages
    dotnet add package Microsoft.NET.Test.Sdk --version "17.*" && \
    dotnet add package xunit --version "2.*" && \
    dotnet add package Moq --version "4.*" && \
    # API packages
    dotnet add package Swashbuckle.AspNetCore --version "6.*" && \
    dotnet restore && \
    cd .. && \
    rm -rf warmup && \
    chmod -R 777 "$NUGET_PACKAGES"

# Final stage
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

# Copy artifacts from builder
COPY --from=builder /root/.dotnet/tools /root/.dotnet/tools
COPY --from=builder /root/.nuget /root/.nuget
COPY --from=builder /etc/profile.d/dotnet-tools.sh /etc/profile.d/

ENV PATH="${PATH}:/root/.dotnet/tools" \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    NUGET_XMLDOC_MODE=skip \
    NUGET_PACKAGES=/root/.nuget/packages