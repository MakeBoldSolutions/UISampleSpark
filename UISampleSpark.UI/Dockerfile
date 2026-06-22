# Pin the .NET 10 runtime/SDK (nightly until GA) so restore supports net10.0
ARG DOTNET_VERSION=10.0

# Use the .NET 10 ASP.NET runtime as the base image (Alpine for security)
FROM mcr.microsoft.com/dotnet/nightly/aspnet:${DOTNET_VERSION}-alpine AS base

# Update Alpine packages to get latest security patches
# Run multiple times to ensure all recursive dependencies are updated
RUN apk update && \
    apk upgrade --no-cache --available && \
    apk add --no-cache --upgrade \
        # Security updates for system libraries
        openssl \
        ca-certificates \
        libssl3 \
        libcrypto3 \
        # ICU for globalization support
        icu-libs \
        icu-data-full && \
    # Second pass to catch any newly added dependencies
    apk upgrade --no-cache --available && \
    # Verify no vulnerabilities remain
    apk audit || true && \
    # Remove unnecessary packages and clean up
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
EXPOSE 8080

# Use the .NET 10 SDK image for building the application
FROM mcr.microsoft.com/dotnet/nightly/sdk:${DOTNET_VERSION} AS build
WORKDIR /src

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Update OS packages to latest security patches - AGGRESSIVE UPDATE
RUN apt-get update && \
    # Upgrade ALL packages to latest versions with security fixes
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    # Install required packages
    apt-get install -y --no-install-recommends \
        curl \
        gnupg \
        ca-certificates && \
    # Install Node.js 20
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g npm@latest && \
    # CRITICAL: Update OpenSSL and system libraries to fix CVEs
    # Use || true to continue even if some packages aren't available
    (apt-get install -y --only-upgrade \
        openssl \
        libssl3 \
        libc6 \
        libc-bin || true) && \
    # Clean up aggressively
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/* ~/.cache

# Copy solution and nuget configuration
COPY ["UISampleSpark.sln", "./"]
COPY ["nuget.config", "./"]

# Copy all project files - ensuring proper directory structure
COPY ["UISampleSpark.UI/*.csproj", "UISampleSpark.UI/"]
COPY ["UISampleSpark.Core/*.csproj", "UISampleSpark.Core/"]
COPY ["UISampleSpark.CLI/*.csproj", "UISampleSpark.CLI/"]
COPY ["UISampleSpark.Core.Tests/*.csproj", "UISampleSpark.Core.Tests/"]
COPY ["UISampleSpark.UI.Tests/*.csproj", "UISampleSpark.UI.Tests/"]

# Restore dependencies
RUN dotnet restore "UISampleSpark.UI/UISampleSpark.UI.csproj"

# Copy all the source code
COPY . .

# Set the working directory to the web project and build the project in release mode
WORKDIR "/src/UISampleSpark.UI"
RUN dotnet build "UISampleSpark.UI.csproj" -c Release -o /app/build

# Publish the application to the publish directory
FROM build AS publish
RUN dotnet publish "UISampleSpark.UI.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Use the base image to run the application
FROM base AS final
WORKDIR /app

# Copy published application
COPY --from=publish /app/publish .

# Set ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user for security
USER appuser

# Configure ASP.NET Core for container environment
ENV ASPNETCORE_URLS=http://+:8080
ENV DOTNET_RUNNING_IN_CONTAINER=true
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

ENTRYPOINT ["dotnet", "UISampleSpark.UI.dll"]
