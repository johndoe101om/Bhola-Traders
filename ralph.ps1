<#
.SYNOPSIS
    Ralph Wiggum Loop (Windows PowerShell Edition)
    Long-running autonomous AI agent loop for Windows.

.DESCRIPTION
    Runs an AI coding agent iteratively against a task list/PRD until
    all tasks are complete or max iterations reached.
    Persists progress to disk after each turn to avoid context rot.

.EXAMPLE
    .\ralph.ps1 -MaxIterations 10
    .\ralph.ps1 -Once
    .\ralph.ps1 -Agent gemini
#>

param (
    [int]$MaxIterations = 0,
    [switch]$Once,
    [string]$Agent = "auto",
    [string]$PrdFile = ".agent\prd\PRD.md",
    [string]$TasksFile = ".agent\tasks\tasks.json",
    [string]$LogFile = ".agent\logs\LOG.md"
)

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " Ralph Wiggum Loop - Long-running AI agents (PowerShell)  " -ForegroundColor Yellow
Write-Host "===========================================================" -ForegroundColor Cyan

# Ensure directories exist
$dirs = @(".agent\history", ".agent\logs", ".agent\prd", ".agent\screenshots", ".agent\tasks")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Ensure log file exists
if (-not (Test-Path $LogFile)) {
    $initialLog = "# Ralph Loop Progress Log`nStarted: " + (Get-Date) + "`n`n"
    Set-Content -Path $LogFile -Value $initialLog -Encoding utf8
}

$iteration = 0
$completed = $false

Write-Host "Starting Ralph Loop..." -ForegroundColor Green
Write-Host "Log file: $LogFile" -ForegroundColor Gray
Write-Host "Tasks:    $TasksFile" -ForegroundColor Gray
Write-Host "PRD:      $PrdFile" -ForegroundColor Gray
Write-Host ""

while (-not $completed) {
    $iteration++
    Write-Host "-----------------------------------------------------------" -ForegroundColor DarkGray
    $timeStr = Get-Date -Format 'HH:mm:ss'
    Write-Host "[Iteration $iteration] $timeStr - Running agent turn..." -ForegroundColor Cyan

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "## [$timestamp] Iteration $iteration"

    # Save iteration checkpoint
    $checkpoint = ".agent\history\iteration_$iteration.json"
    @{
        iteration = $iteration
        timestamp = $timestamp
        status = "in-progress"
    } | ConvertTo-Json | Set-Content -Path $checkpoint -Encoding utf8

    # Check for single-run flag
    if ($Once) {
        Write-Host "Executed single iteration (Once mode)." -ForegroundColor Yellow
        break
    }

    # Check max iterations
    if ($MaxIterations -gt 0 -and $iteration -ge $MaxIterations) {
        Write-Host "Reached max iterations ($MaxIterations). Exiting loop." -ForegroundColor Yellow
        break
    }

    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host " Ralph Loop Finished ($iteration iterations)" -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
