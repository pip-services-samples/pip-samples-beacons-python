#!/usr/bin/env pwsh

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$component = Get-Content -Path "component.json" | ConvertFrom-Json
$image="$($component.registry)/$($component.name):$($component.version)-$($component.build)-rc"
$latestImage="$($component.registry)/$($component.name):latest"

# Build docker image
docker build -f docker/Dockerfile -t $image -t $latestImage .

# Set environment variables
$env:IMAGE = $image

try {
    # Workaround to remove dangling images
    docker-compose -f ./docker/docker-compose.yml down

    docker-compose -f ./docker/docker-compose.yml up -d

    Start-Sleep -Seconds 10
    Invoke-WebRequest -Uri http://localhost:8080/heartbeat

    $postParams = @{'beacons'=
        @{'filter'=@{
            'site_id'=''
            'udi'=''
    }}} | ConvertTo-Json

    $header = @{
        "Accept"="application/json"
        "Content-Type"="application/json"
    }

    Invoke-WebRequest -Uri http://localhost:8080/v1/beacons/get_beacons -Method Post -Body $postParams -Headers $header

    Write-Host "The container was successfully built."
} finally {
    docker-compose -f ./docker/docker-compose.yml down
}

