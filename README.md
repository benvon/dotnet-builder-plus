# dotnet-builder-plus

A .NET builder image that contains common tools for building .NET applications in an Azure DevOps (ADO) environment. This image is based on the official Microsoft .NET SDK image and includes additional tools and packages commonly needed for enterprise .NET development. **This image is intentionally very large.** The goal is to speed up CI builds of dotnet applications by pre-caching as much of the dotNet frameworks and packages as possible so that this work doesn't have to be done on every CI run.

## Features

- Based on Microsoft's official .NET SDK image (version 8.0)
- Pre-installed global tools:
  - Entity Framework Core CLI (`dotnet-ef`)
  - SonarScanner for .NET (`dotnet-sonarscanner`)
  - ReportGenerator (`dotnet-reportgenerator-globaltool`)
  - NuGet Package Outdated Checker (`dotnet-outdated-tool`)
- Azure CLI integration
- Pre-warmed NuGet package cache
- Pre-configured Entity Framework Core tooling
- Additional development tools:
  - Java Development Kit (JDK)
  - jq for JSON processing
  - NuGet CLI
  - curl and other essential utilities

## Environment Variables

The image sets several environment variables to optimize the build process:

- `NUGET_PACKAGES=/packages/.nuget/packages`
- `PATH` includes `/packages/.dotnet/tools`
- `DOTNET_CLI_TELEMETRY_OPTOUT=1`
- `DOTNET_NOLOGO=1`
- `NUGET_XMLDOC_MODE=skip`

## Usage

The image is designed to be used in Azure DevOps pipeline builds. It includes all necessary tools for:

- Building .NET applications
- Running Entity Framework Core migrations
- Code analysis with SonarQube
- Test coverage reporting
- Package management and updates

## Example Usage in Azure DevOps Pipeline

```yaml
pool:
  vmImage: 'ubuntu-latest'
  container:
    image: gcr.io/benvon/dotnet-builder-plus:v0.2.1-dotnet8.0
```

## Pre-warmed Components

The image includes pre-warmed components to speed up builds:

- Common NuGet packages
- Entity Framework Core tooling
- Sample projects for warmup (console, webapi, classlib, xunit)

## License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details.
