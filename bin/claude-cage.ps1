# Claude Cage Lite - PowerShell launcher for Windows
# Requires Docker Desktop

param(
    [string]$Volume = "",
    [switch]$Rebuild,
    [switch]$Shell,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ClaudeArgs
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir
$ImageName = if ($env:CLAUDE_CAGE_IMAGE) { $env:CLAUDE_CAGE_IMAGE } else { "claude-cage-lite" }
$DefaultVolume = "claude-cage-home"

function Show-Help {
    @"
Usage: .\claude-cage.ps1 [OPTIONS] [CLAUDE_ARGS...]

Lightweight isolated sandbox for Claude Code on Windows.
Claude login state is completely isolated from the host.

Options:
  -Volume NAME     Use named volume suffix (e.g. -Volume work)
  -Rebuild         Force rebuild the Docker image
  -Shell           Enter an interactive bash shell inside the container
  -Help            Show this help

Examples:
  .\claude-cage.ps1
  .\claude-cage.ps1 -Volume personal
  .\claude-cage.ps1 -Rebuild
  .\claude-cage.ps1 "explain this codebase"
"@
}

if ($Help) {
    Show-Help
    exit 0
}

# Check Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not in PATH. Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
}

try {
    docker info 2>&1 | Out-Null
} catch {
    Write-Error "Docker daemon is not running. Please start Docker Desktop."
}

$VolumeName = $DefaultVolume
if ($Volume) {
    $VolumeName = "$DefaultVolume-$Volume"
}

# Ensure volume exists (holds entire /home/claude — login state fully isolated)
docker volume create $VolumeName 2>&1 | Out-Null

# Build image if needed
$needBuild = $Rebuild
if (-not $needBuild) {
    $null = docker image inspect $ImageName 2>&1
    if ($LASTEXITCODE -ne 0) { $needBuild = $true }
}

if ($needBuild) {
    Write-Host "→ Building image: $ImageName"
    docker build -t $ImageName $ProjectRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$ProjectDir = (Get-Location).Path

Write-Host "→ Project : $ProjectDir"
Write-Host "→ Volume  : $VolumeName  (Claude login state is fully isolated)"
Write-Host "→ Image   : $ImageName"
Write-Host ""

$dockerArgs = @(
    "run", "--rm", "-it",
    "--name", "claude-cage-$PID",
    "-v", "${ProjectDir}:/workspace:rw",
    "-v", "${VolumeName}:/home/claude:rw",
    "-e", "HOME=/home/claude",
    "-e", "TERM=xterm-256color",
    "-w", "/workspace",
    "--user", "1000:1000"
)

# Pass proxy env if present
foreach ($var in @("HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY", "http_proxy", "https_proxy")) {
    $val = [Environment]::GetEnvironmentVariable($var)
    if ($val) {
        $dockerArgs += "-e", "${var}=${val}"
    }
}

$dockerArgs += $ImageName

if ($Shell) {
    $dockerArgs += "bash"
} else {
    $dockerArgs += "claude"
    if ($ClaudeArgs) {
        $dockerArgs += $ClaudeArgs
    }
}

& docker @dockerArgs
exit $LASTEXITCODE
