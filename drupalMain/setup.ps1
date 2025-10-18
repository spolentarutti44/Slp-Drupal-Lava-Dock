# Multi-Service E-Learning Platform Setup Script for Windows
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Multi-Service E-Learning Platform Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Create local persistence directories
Write-Host "Creating local persistence directories..." -ForegroundColor Yellow
$directories = @("drupal-data", "mariadb-data", "laravel-data", "laravel-db-data", "ollama-data")

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Exists: $dir" -ForegroundColor Gray
    }
}

Write-Host "Persistence directories ready" -ForegroundColor Green
Write-Host ""

# Start Docker services
Write-Host "Starting Docker services..." -ForegroundColor Yellow
docker-compose up -d

Write-Host ""
Write-Host "Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check if Laravel is installed
Write-Host ""
Write-Host "Checking Laravel installation..." -ForegroundColor Yellow
$laravelInstalled = Test-Path ".\laravel-data\artisan"

if ($laravelInstalled) {
    Write-Host "Laravel already installed" -ForegroundColor Green
} else {
    Write-Host "Installing Laravel (this may take a few minutes)..." -ForegroundColor Yellow
    docker-compose exec laravel composer create-project laravel/laravel .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Note: Laravel installation will complete on container restart" -ForegroundColor Yellow
    }
}

# Setup Ollama models
Write-Host ""
Write-Host "Setting up Ollama LLM models..." -ForegroundColor Yellow
Write-Host "Pulling llama2 model (this may take a while)..." -ForegroundColor Yellow
docker-compose exec ollama ollama pull llama2

if ($LASTEXITCODE -ne 0) {
    Write-Host "Note: You can pull Ollama models manually later" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Service URLs:" -ForegroundColor White
Write-Host "  - Drupal CMS:         http://localhost" -ForegroundColor Cyan
Write-Host "  - Laravel App:        http://localhost:8000" -ForegroundColor Cyan
Write-Host "  - Adminer (DB Admin): http://localhost:8080" -ForegroundColor Cyan
Write-Host "  - Ollama API:         http://localhost:11434" -ForegroundColor Cyan
Write-Host ""

Write-Host "Database Credentials:" -ForegroundColor White
Write-Host "  Drupal DB:" -ForegroundColor Yellow
Write-Host "    - Host: mariadb1"
Write-Host "    - Database: drupaldb"
Write-Host "    - User: mariadb"
Write-Host "    - Password: mariadb"
Write-Host ""

Write-Host "  Laravel DB:" -ForegroundColor Yellow
Write-Host "    - Host: laravel-db"
Write-Host "    - Database: laraveldb"
Write-Host "    - User: laravel"
Write-Host "    - Password: laravel"
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Configure Drupal at http://localhost"
Write-Host "  2. Generate Laravel app key: docker-compose exec laravel php artisan key:generate"
Write-Host "  3. Run Laravel migrations: docker-compose exec laravel php artisan migrate"
Write-Host ""

