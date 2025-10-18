# Multi-Service E-Learning Platform

A comprehensive e-learning platform that integrates **Drupal CMS**, **Laravel**, and **Ollama LLM** using Docker.

## Architecture Overview

This application consists of 5 main services:

1. **Drupal** - Content Management System for course content
2. **MariaDB (Drupal)** - Database for Drupal
3. **Laravel** - User authentication and progress tracking
4. **MariaDB (Laravel)** - Database for Laravel
5. **Ollama** - AI-powered learning assistant and tutoring
6. **Adminer** - Database administration tool

## Features

### Drupal CMS
- Course content management
- Video lectures and documents
- Quizzes and forum discussions
- Content tagging and categorization

### Laravel Application
- User registration and authentication
- Learning progress tracking
- Course completion monitoring
- Analytics dashboards
- Certificate management

### Ollama LLM Integration
- AI-driven tutoring
- Real-time content-related queries
- Language translation support
- Personalized content recommendations

## Prerequisites

- Docker Desktop installed and running
- Docker Compose v2.0+
- At least 8GB RAM available
- (Optional) NVIDIA GPU for better LLM performance

## Quick Start

### Windows

```powershell
# Navigate to the project directory
cd drupalMain

# Run the setup script
.\setup.ps1

# Or manually start services
docker-compose up -d
```

### Linux/Mac

```bash
# Navigate to the project directory
cd drupalMain

# Make setup script executable
chmod +x setup.sh

# Run the setup script
./setup.sh

# Or manually start services
docker-compose up -d
```

## Service URLs

Once the services are running, access them at:

- **Drupal CMS**: http://localhost
- **Laravel Application**: http://localhost:8000
- **Adminer (Database Admin)**: http://localhost:8080
- **Ollama API**: http://localhost:11434

## Database Configuration

### Drupal Database
- Host: `mariadb1`
- Database: `drupaldb`
- Username: `mariadb`
- Password: `mariadb`

### Laravel Database
- Host: `laravel-db`
- Database: `laraveldb`
- Username: `laravel`
- Password: `laravel`

## Initial Setup

### 1. Configure Drupal

1. Visit http://localhost
2. Select installation profile
3. Configure database connection using credentials above
4. Complete site configuration

### 2. Setup Laravel

```bash
# Generate application key
docker-compose exec laravel php artisan key:generate

# Run database migrations
docker-compose exec laravel php artisan migrate

# (Optional) Seed the database
docker-compose exec laravel php artisan db:seed
```

### 3. Setup Ollama Models

```bash
# Pull a language model (e.g., llama2)
docker-compose exec ollama ollama pull llama2

# Or pull a smaller model for testing
docker-compose exec ollama ollama pull tinyllama

# List available models
docker-compose exec ollama ollama list
```

## Testing the LLM Service

### Using curl (Linux/Mac)

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "Explain the concept of inheritance in object-oriented programming.",
  "stream": false
}'
```

### Using PowerShell (Windows)

```powershell
$body = @{
    model = "llama2"
    prompt = "Explain the concept of inheritance in object-oriented programming."
    stream = $false
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method POST -Body $body -ContentType "application/json"
```

## Useful Commands

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f laravel
docker-compose logs -f ollama
```

### Restart services
```bash
# All services
docker-compose restart

# Specific service
docker-compose restart laravel
```

### Stop services
```bash
docker-compose down
```

### Stop services and remove volumes (WARNING: This deletes all data)
```bash
docker-compose down -v
```

### Access service shells
```bash
# Laravel container
docker-compose exec laravel bash

# Ollama container
docker-compose exec ollama bash
```

## Local Persistence

All data is persisted in local directories:

- `drupal-data/` - Drupal files
- `mariadb-data/` - Drupal database
- `laravel-data/` - Laravel application files
- `laravel-db-data/` - Laravel database
- `ollama-data/` - Ollama models and data

## Development Workflow

### Laravel Development

1. Make changes to files in `laravel-data/`
2. Changes are automatically reflected (volume mount)
3. Clear cache if needed:
   ```bash
   docker-compose exec laravel php artisan cache:clear
   docker-compose exec laravel php artisan config:clear
   ```

### Drupal Development

1. Install modules through Drupal admin panel
2. Or use Composer:
   ```bash
   docker-compose exec drupal1 composer require drupal/module_name
   ```

## Integration Between Services

### Laravel → Ollama
Laravel can communicate with Ollama using the environment variable `LLM_SERVICE_URL`:
```php
$response = Http::post(env('LLM_SERVICE_URL') . '/api/generate', [
    'model' => 'llama2',
    'prompt' => $userQuestion,
]);
```

### Drupal → Laravel
Use REST API or shared database approach for integration.

### Service Network
All services are on the same Docker network (`app-network`) and can communicate using their service names.

## Troubleshooting

### Ollama GPU Support
If you don't have an NVIDIA GPU, comment out the GPU section in `docker-compose.yml`:
```yaml
# deploy:
#   resources:
#     reservations:
#       devices:
#         - driver: nvidia
#           count: all
#           capabilities: [gpu]
```

### Port Conflicts
If ports are already in use, modify the port mappings in `docker-compose.yml`:
```yaml
ports:
  - "8081:80"  # Change 80 to 8081 for Drupal
```

### Laravel Permission Issues
```bash
docker-compose exec laravel chown -R www-data:www-data /var/www/html
docker-compose exec laravel chmod -R 755 /var/www/html/storage
```

## Contributing

This is a starter template for a multi-service e-learning platform. Feel free to extend and customize it based on your specific requirements.

## License

MIT License - Feel free to use and modify as needed.

