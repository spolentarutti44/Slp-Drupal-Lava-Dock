# Quick Start Guide

Get your multi-service e-learning platform up and running in minutes!

## Prerequisites Checklist

- [ ] Docker Desktop installed and running
- [ ] At least 8GB RAM available
- [ ] At least 20GB disk space free
- [ ] Ports 80, 8000, 8080, and 11434 available

## Quick Start (Windows)

```powershell
# Navigate to the project directory
cd drupalMain

# Run the setup script
.\setup.ps1

# Wait for all services to start (this may take a few minutes)
```

## Quick Start (Linux/Mac)

```bash
# Navigate to the project directory
cd drupalMain

# Make setup script executable
chmod +x setup.sh

# Run the setup script
./setup.sh
```

## Manual Setup (All Platforms)

If the automated scripts don't work, follow these steps:

### 1. Start Services

```bash
cd drupalMain
docker-compose up -d
```

### 2. Wait for Services

```bash
# Check service status
docker-compose ps

# All services should show "Up" status
```

### 3. Install Laravel (if not auto-installed)

```bash
# Wait for the Laravel container to be ready
docker-compose exec laravel composer create-project laravel/laravel . --prefer-dist

# Generate application key
docker-compose exec laravel php artisan key:generate

# Set permissions
docker-compose exec laravel chown -R www-data:www-data /var/www/html
docker-compose exec laravel chmod -R 755 /var/www/html/storage
```

### 4. Setup Ollama Models

```bash
# Pull the llama2 model (recommended for production)
docker-compose exec ollama ollama pull llama2

# OR pull a smaller model for testing
docker-compose exec ollama ollama pull tinyllama

# Verify model is installed
docker-compose exec ollama ollama list
```

## Verify Installation

### 1. Check All Services Are Running

```bash
docker-compose ps
```

Expected output:
```
NAME            STATUS          PORTS
drupal1         Up              0.0.0.0:80->80/tcp
laravel         Up              0.0.0.0:8000->8000/tcp
mariadb1        Up              3306/tcp
laravel-db      Up              3306/tcp
ollama          Up              0.0.0.0:11434->11434/tcp
adminer         Up              0.0.0.0:8080->8080/tcp
```

### 2. Test Each Service

#### Test Drupal
Open browser: http://localhost
- You should see the Drupal installation page

#### Test Laravel
Open browser: http://localhost:8000
- You should see the Laravel welcome page

#### Test Adminer
Open browser: http://localhost:8080
- You should see the Adminer login page

#### Test Ollama API
```bash
# Windows PowerShell
Invoke-RestMethod -Uri http://localhost:11434/api/tags -Method GET

# Linux/Mac
curl http://localhost:11434/api/tags
```

Expected: JSON response with list of models

## Initial Configuration

### Configure Drupal

1. Open http://localhost in your browser
2. Select "Standard" installation profile
3. Database configuration:
   - Database type: **MySQL, MariaDB, Percona Server, or equivalent**
   - Database name: **drupaldb**
   - Database username: **mariadb**
   - Database password: **mariadb**
   - Advanced options > Host: **mariadb1**
4. Complete site information form
5. Done! Your Drupal site is ready

### Configure Laravel

```bash
# Generate application key (if not done)
docker-compose exec laravel php artisan key:generate

# Run migrations (after creating your migrations)
docker-compose exec laravel php artisan migrate

# Clear all caches
docker-compose exec laravel php artisan config:clear
docker-compose exec laravel php artisan cache:clear
docker-compose exec laravel php artisan route:clear
```

### Install OllamaService in Laravel

1. Copy `OllamaService.php` to Laravel:
```bash
# Windows
docker cp laravel-app/OllamaService.php laravel:/var/www/html/app/Services/OllamaService.php

# Linux/Mac
docker-compose exec laravel mkdir -p /var/www/html/app/Services
docker cp laravel-app/OllamaService.php laravel:/var/www/html/app/Services/
```

2. Copy the controller:
```bash
docker cp laravel-app/ExampleController.php laravel:/var/www/html/app/Http/Controllers/LearningAssistantController.php
```

3. Add routes to `routes/api.php` (see `api-routes-example.php`)

## Test the Integration

### Test Laravel → Ollama

```bash
# Health check
curl http://localhost:8000/api/llm/health

# Ask the AI tutor
curl -X POST http://localhost:8000/api/llm/tutor \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is object-oriented programming?",
    "context": "Introduction to Programming"
  }'
```

### Test from Inside Drupal

```bash
# Test network connectivity
docker-compose exec drupal1 curl http://laravel:8000/api/llm/health
```

## Common First-Time Issues

### Issue: Ports already in use

**Solution:** Change port mappings in `docker-compose.yml`

```yaml
# For example, change Drupal from port 80 to 8081
ports:
  - "8081:80"
```

### Issue: Ollama GPU error

**Solution:** Comment out GPU configuration if you don't have NVIDIA GPU

Edit `docker-compose.yml` and comment out:
```yaml
# deploy:
#   resources:
#     reservations:
#       devices:
#         - driver: nvidia
#           count: all
#           capabilities: [gpu]
```

### Issue: Laravel showing 500 error

**Solution:** Check permissions and generate key

```bash
docker-compose exec laravel php artisan key:generate
docker-compose exec laravel chown -R www-data:www-data /var/www/html
docker-compose exec laravel chmod -R 755 /var/www/html/storage
```

### Issue: Can't connect to database from Drupal

**Solution:** Make sure you're using the service name as host

- Host should be: `mariadb1` (NOT `localhost` or `127.0.0.1`)
- This is the Docker service name from docker-compose.yml

### Issue: Ollama model not found

**Solution:** Pull the model

```bash
docker-compose exec ollama ollama pull llama2
```

## Next Steps After Installation

1. **Customize Drupal**
   - Install additional modules
   - Create content types for courses
   - Set up user roles and permissions

2. **Develop Laravel Features**
   - Create user authentication system
   - Build progress tracking database
   - Implement API endpoints

3. **Integrate Services**
   - Set up Drupal to call Laravel API
   - Implement single sign-on
   - Create AI-powered features

4. **Add Content**
   - Create courses in Drupal
   - Set up quiz system
   - Configure forums

5. **Test AI Features**
   - Test tutoring functionality
   - Try content translation
   - Generate quiz questions

## Useful Commands

```bash
# View logs
docker-compose logs -f

# Restart a service
docker-compose restart laravel

# Stop all services
docker-compose down

# Stop and remove all data (WARNING!)
docker-compose down -v

# Access a container shell
docker-compose exec laravel bash
docker-compose exec drupal1 bash

# Check resource usage
docker stats
```

## Getting Help

If you encounter issues:

1. Check the logs: `docker-compose logs -f [service-name]`
2. Verify services are running: `docker-compose ps`
3. Read the full documentation: `README.md` and `INTEGRATION.md`
4. Check Docker resources: Docker Desktop → Settings → Resources

## Production Deployment

**Warning:** This setup is for development only!

For production deployment:
- [ ] Change all default passwords
- [ ] Enable HTTPS/SSL
- [ ] Configure proper backups
- [ ] Set up monitoring
- [ ] Implement security best practices
- [ ] Use environment-specific configuration
- [ ] Set up reverse proxy (nginx/Caddy)
- [ ] Configure firewall rules

See `README.md` for more details on production deployment.

---

**Congratulations!** 🎉 Your multi-service e-learning platform is now running!

Visit http://localhost to start using Drupal and http://localhost:8000 for Laravel.

