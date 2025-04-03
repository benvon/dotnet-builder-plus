ARG DOTNET_IMAGE_VERSION=8.0

FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_IMAGE_VERSION} AS builder

ARG DOTNET_IMAGE_VERSION=8.0

# Set environment variables
ENV NUGET_PACKAGES=/root/.nuget/packages \
    PATH="${PATH}:/root/.dotnet/tools" \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    NUGET_XMLDOC_MODE=skip

# Copy package management files
COPY packages /packages
RUN chmod +x /packages/install-packages.sh && \
    chmod +x /packages/install-tools.sh

# Install global tools
RUN /packages/install-tools.sh /packages/Dockerfile.Tools.${DOTNET_IMAGE_VERSION}.csproj && \
    echo 'export PATH="$PATH:/root/.dotnet/tools"' > /etc/profile.d/dotnet-tools.sh && \
    chmod +x /etc/profile.d/dotnet-tools.sh

# # Create warmup project with common packages
# RUN DOTNET_LATEST=$(dotnet --version) && \
#     echo "Using .NET SDK version: $DOTNET_LATEST"

WORKDIR /warmup
# Create solution and projects
RUN dotnet new sln -n warmup && \
    dotnet new console -n warmup-console && \
    dotnet new webapi -n warmup-webapi && \
    dotnet new classlib -n warmup-lib && \
    dotnet new xunit -n warmup-tests && \
    dotnet new webapi -n warmup-ef

WORKDIR /warmup/warmup-ef
# Setup EF warmup project
RUN VERSION=$(grep Microsoft.EntityFrameworkCore.SqlServer /packages/Dockerfile.Packages.${DOTNET_IMAGE_VERSION}.csproj \
      | grep -o 'Version="[^"]*"' \
      | sed 's/.*Version="\([^"]*\)".*/\1/') && \
    dotnet add package Microsoft.EntityFrameworkCore.SqlServer --version "$VERSION" && \
    VERSION=$(grep Microsoft.EntityFrameworkCore.Design /packages/Dockerfile.Packages.${DOTNET_IMAGE_VERSION}.csproj \
      | grep -o 'Version="[^"]*"' \
      | sed 's/.*Version="\([^"]*\)".*/\1/') && \
    dotnet add package Microsoft.EntityFrameworkCore.Design --version "$VERSION"

COPY packages/ef-warmup/Models /warmup/warmup-ef/Models
COPY packages/ef-warmup/Data /warmup/warmup-ef/Data
COPY packages/ef-warmup/Program.cs /warmup/warmup-ef/Program.cs

# Warm up EF tooling
WORKDIR /warmup/warmup-ef
RUN dotnet tool restore && \
    rm -rf Migrations && \
    dotnet ef migrations add InitialCreate && \
    dotnet ef migrations script --idempotent && \
    dotnet ef dbcontext info

WORKDIR /warmup
# Add projects to solution
RUN dotnet sln add warmup-console/warmup-console.csproj && \
    dotnet sln add warmup-webapi/warmup-webapi.csproj && \
    dotnet sln add warmup-lib/warmup-lib.csproj && \
    dotnet sln add warmup-tests/warmup-tests.csproj && \
    dotnet sln add warmup-ef/warmup-ef.csproj

# Install packages and build
RUN /packages/install-packages.sh /packages/Dockerfile.Packages.${DOTNET_IMAGE_VERSION}.csproj && \
    dotnet build --no-restore
WORKDIR /warmup/warmup-ef
# Run EF migrations
RUN dotnet ef migrations add SecondaryCreate && \
    dotnet ef migrations script
WORKDIR /warmup

# Clean up
RUN rm -rf warmup* && \
    chmod -R 777 "$NUGET_PACKAGES"

# Final stage
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_IMAGE_VERSION} AS final
ARG DOTNET_IMAGE_VERSION=8.0
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