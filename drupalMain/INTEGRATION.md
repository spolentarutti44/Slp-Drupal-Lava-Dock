# Service Integration Guide

This guide explains how to integrate Drupal, Laravel, and Ollama LLM in your e-learning platform.

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Drupal    │      │   Laravel    │      │   Ollama    │
│   (CMS)     │◄────►│  (Backend)   │◄────►│    (LLM)    │
│   Port 80   │      │  Port 8000   │      │  Port 11434 │
└─────────────┘      └──────────────┘      └─────────────┘
       │                     │
       │                     │
       ▼                     ▼
┌─────────────┐      ┌──────────────┐
│  MariaDB 1  │      │  MariaDB 2   │
│ (Drupal DB) │      │ (Laravel DB) │
└─────────────┘      └──────────────┘
```

## 1. Drupal ↔ Laravel Integration

### Option A: REST API (Recommended)

**In Laravel:**
Create API endpoints for user management and progress tracking:

```php
// routes/api.php
Route::middleware('api')->group(function () {
    Route::post('/users/register', [UserController::class, 'register']);
    Route::post('/users/authenticate', [UserController::class, 'authenticate']);
    Route::get('/users/{id}/progress', [ProgressController::class, 'getProgress']);
    Route::post('/users/{id}/progress', [ProgressController::class, 'updateProgress']);
});
```

**In Drupal:**
Use Guzzle HTTP client to communicate with Laravel:

```php
<?php
// In a Drupal custom module

use GuzzleHttp\Client;

function mymodule_get_user_progress($user_id) {
  $client = new Client([
    'base_uri' => 'http://laravel:8000',
  ]);
  
  $response = $client->get("/api/users/{$user_id}/progress");
  return json_decode($response->getBody(), TRUE);
}
```

### Option B: Shared Database

Both Drupal and Laravel can share tables for user data:

**Laravel Migration:**
```php
// Create a shared users table
Schema::create('shared_users', function (Blueprint $table) {
    $table->id();
    $table->string('email')->unique();
    $table->string('name');
    $table->timestamp('email_verified_at')->nullable();
    $table->timestamps();
});
```

### Option C: Single Sign-On (SSO)

Implement OAuth2 or JWT tokens for seamless authentication:

1. Install Laravel Passport or Sanctum
2. Install Drupal Simple OAuth module
3. Configure shared authentication

## 2. Laravel ↔ Ollama Integration

### Basic Usage

The `OllamaService` class provides all necessary methods:

```php
use App\Services\OllamaService;

class CourseController extends Controller
{
    protected $ollama;
    
    public function __construct(OllamaService $ollama)
    {
        $this->ollama = $ollama;
    }
    
    public function getHelp(Request $request)
    {
        $response = $this->ollama->getTutoringResponse(
            $request->input('question'),
            $request->input('course_context')
        );
        
        return response()->json($response);
    }
}
```

### Example API Endpoints

```bash
# Ask the AI tutor
curl -X POST http://localhost:8000/api/llm/tutor \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is polymorphism in OOP?",
    "context": "Object-Oriented Programming course"
  }'

# Translate content
curl -X POST http://localhost:8000/api/llm/translate \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Welcome to our e-learning platform",
    "language": "Spanish"
  }'

# Generate quiz
curl -X POST http://localhost:8000/api/llm/generate-quiz \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Inheritance allows a class to inherit properties...",
    "num_questions": 5
  }'
```

## 3. Drupal ↔ Ollama Integration

### Direct Integration (Optional)

Create a Drupal custom module to interact with Ollama:

```php
<?php
// mymodule.module

use GuzzleHttp\Client;

function mymodule_ask_ai($question, $context = '') {
  $client = new Client(['base_uri' => 'http://ollama:11434']);
  
  $prompt = "You are an educational tutor. Topic: {$context}. Question: {$question}";
  
  $response = $client->post('/api/generate', [
    'json' => [
      'model' => 'llama2',
      'prompt' => $prompt,
      'stream' => false,
    ],
  ]);
  
  $data = json_decode($response->getBody(), TRUE);
  return $data['response'];
}
```

### Via Laravel (Recommended)

Use Laravel as a middleware between Drupal and Ollama:

```php
// Drupal calls Laravel API
$client = new Client(['base_uri' => 'http://laravel:8000']);
$response = $client->post('/api/llm/tutor', [
  'json' => [
    'question' => $question,
    'context' => $context,
  ],
]);
```

## 4. Complete Integration Example

### User Learning Flow

1. **User Access** (Drupal)
   - Student logs in to Drupal
   - Browses available courses
   - Selects a course to study

2. **Progress Tracking** (Laravel)
   - Drupal sends course completion data to Laravel API
   - Laravel stores progress in its database
   - Laravel generates analytics

3. **AI Assistance** (Ollama via Laravel)
   - Student asks question in Drupal
   - Drupal forwards question to Laravel
   - Laravel queries Ollama LLM
   - Response flows back to student

### Example Implementation

**Step 1: Drupal Form**
```php
<?php
// mymodule/src/Form/AskAIForm.php

namespace Drupal\mymodule\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use GuzzleHttp\Client;

class AskAIForm extends FormBase {
  
  public function buildForm(array $form, FormStateInterface $form_state) {
    $form['question'] = [
      '#type' => 'textarea',
      '#title' => $this->t('Ask the AI Tutor'),
      '#required' => TRUE,
    ];
    
    $form['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Get Answer'),
    ];
    
    return $form;
  }
  
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $question = $form_state->getValue('question');
    
    // Call Laravel API
    $client = new Client(['base_uri' => 'http://laravel:8000']);
    $response = $client->post('/api/llm/tutor', [
      'json' => ['question' => $question],
    ]);
    
    $data = json_decode($response->getBody(), TRUE);
    
    \Drupal::messenger()->addMessage($data['answer']);
  }
}
```

**Step 2: Laravel Controller**
```php
<?php
// Already implemented in LearningAssistantController.php

// This receives the request from Drupal and forwards to Ollama
```

**Step 3: Display in Drupal**
```php
<?php
// mymodule.module

function mymodule_theme() {
  return [
    'ai_tutor_response' => [
      'variables' => ['answer' => NULL],
      'template' => 'ai-tutor-response',
    ],
  ];
}
```

## 5. Database Integration

### User Progress Tracking

**Laravel Migration:**
```php
Schema::create('user_progress', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained();
    $table->string('course_id'); // Drupal course node ID
    $table->integer('completion_percentage')->default(0);
    $table->json('completed_sections')->nullable();
    $table->timestamp('last_accessed_at')->nullable();
    $table->timestamps();
});
```

**API to Update Progress:**
```php
// POST /api/users/{id}/progress
public function updateProgress(Request $request, $id)
{
    UserProgress::updateOrCreate(
        [
            'user_id' => $id,
            'course_id' => $request->course_id,
        ],
        [
            'completion_percentage' => $request->percentage,
            'completed_sections' => $request->sections,
            'last_accessed_at' => now(),
        ]
    );
    
    return response()->json(['success' => true]);
}
```

## 6. Service Configuration

### Environment Variables

**Laravel (.env):**
```env
LLM_SERVICE_URL=http://ollama:11434
LLM_DEFAULT_MODEL=llama2
LLM_TIMEOUT=60
```

**Drupal (settings.php):**
```php
$settings['laravel_api_base_url'] = 'http://laravel:8000';
$settings['laravel_api_key'] = 'your-api-key-here';
```

## 7. Security Considerations

### API Authentication

**Laravel Sanctum:**
```php
// Protect your API routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/llm/tutor', [LearningAssistantController::class, 'askTutor']);
});
```

**Drupal API Key:**
```php
// Send authentication header
$client = new Client(['base_uri' => 'http://laravel:8000']);
$response = $client->post('/api/llm/tutor', [
  'headers' => [
    'Authorization' => 'Bearer ' . $api_key,
    'Accept' => 'application/json',
  ],
  'json' => ['question' => $question],
]);
```

### Rate Limiting

**Laravel:**
```php
// In RouteServiceProvider.php
RateLimiter::for('ai', function (Request $request) {
    return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
});

// Apply to routes
Route::middleware(['throttle:ai'])->group(function () {
    // AI routes
});
```

## 8. Testing Integration

### Test Ollama Connection
```bash
# From host machine
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "Hello",
  "stream": false
}'

# From Laravel container
docker-compose exec laravel php artisan tinker
>>> $service = new App\Services\OllamaService();
>>> $service->isAvailable();
>>> $service->generate("What is Laravel?");
```

### Test Laravel API
```bash
# Health check
curl http://localhost:8000/api/llm/health

# Ask tutor
curl -X POST http://localhost:8000/api/llm/tutor \
  -H "Content-Type: application/json" \
  -d '{"question": "What is PHP?"}'
```

### Test Drupal Integration
```bash
# Make sure Drupal can reach Laravel
docker-compose exec drupal1 curl http://laravel:8000/api/llm/health
```

## 9. Monitoring and Logging

### Laravel Logging
```php
// Log LLM interactions
Log::channel('ollama')->info('LLM Query', [
    'user_id' => $user->id,
    'question' => $question,
    'response_time' => $responseTime,
]);
```

### Performance Monitoring
```php
// Track response times
use Illuminate\Support\Facades\Cache;

$startTime = microtime(true);
$response = $this->ollama->generate($prompt);
$duration = microtime(true) - $startTime;

Cache::put("llm_avg_response_time", $duration, 3600);
```

## 10. Troubleshooting

### Common Issues

**Ollama not responding:**
```bash
# Check if Ollama is running
docker-compose ps ollama

# Check Ollama logs
docker-compose logs ollama

# Pull a model if needed
docker-compose exec ollama ollama pull llama2
```

**Laravel can't connect to Ollama:**
```bash
# Test from Laravel container
docker-compose exec laravel curl http://ollama:11434
```

**Drupal can't reach Laravel:**
```bash
# Test from Drupal container
docker-compose exec drupal1 curl http://laravel:8000/api/llm/health
```

## Next Steps

1. Implement authentication between services
2. Add caching for LLM responses
3. Create Drupal blocks/widgets for AI features
4. Build analytics dashboard in Laravel
5. Set up CI/CD pipeline
6. Configure production environment variables
7. Implement proper error handling and logging

For more information, see the main README.md file.

