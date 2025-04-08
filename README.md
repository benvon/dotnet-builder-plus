# dotnet-builder-plus

A .NET builder image that contains common tools for building .NET applications in an Azure DevOps (ADO) environment. This image is based on the official Microsoft .NET SDK image and includes additional tools and packages commonly needed for enterprise .NET development.

Attempts have been made to minimize the size of this image by trimming cached python libraries from the Azure CLI installation and using a minimal JRE installation.

## Features

- Based on Microsoft's official .NET SDK image (version 8.0)
- Azure CLI integration
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
- Code analysis with SonarQube
- Test coverage reporting
- Package management and updates

## Example Usage in Azure DevOps Pipeline

```yaml
pool:
  vmImage: 'ubuntu-latest'
  container:
    image: gcr.io/benvon/dotnet-builder-plus:v0.2.1-dotnet8.0
    options: >
      --mount type=bind,src=$(Pipeline.Workspace)/.nuget/packages,dst=/packages/.nuget/packages
      --env NUGET_PACKAGES=/packages.nuget/packages

    ...
        - task: Cache@2
          displayName: Cache nuget packages
          inputs:
            key: 'nuget | "$(Agent.OS)" | **/*.csjproj,**/*.packages.json,!**/bin/**,!**/obj/**'
            path: $(Pipeline.Workspace)/.nuget/packages
```

## License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details.
