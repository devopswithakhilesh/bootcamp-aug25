# Failure Monitoring POC

A proof-of-concept system for monitoring application failures with AI-powered log analysis, running on Minikube.

## Overview

This POC demonstrates an automated failure monitoring system with the following components:

1. **Java Application** - Spring Boot app with controllable failure injection
2. **Health Checker** - Python-based CronJob that monitors the app every 5 minutes
3. **AI Analysis** - Local Ollama instance with Gemma 2B model for log analysis
4. **Dashboard** - React-based web UI for monitoring and control
5. **PostgreSQL** - Database for storing health check results
6. **AI Chat Interface** - Interactive chat with local AI assistant
7. **RAG System** - Knowledge base with document upload and vector search (Qdrant + embeddings)

## Architecture

```
┌─────────────────────────────────────────┐
│           Dashboard                     │
│  (React + Node.js - Port 30001)        │
│  ┌───────────┐ ┌──────────┐ ┌────────┐ │
│  │Monitoring │ │ AI Chat  │ │ Docs   │ │
│  └───────────┘ └──────────┘ └────────┘ │
└────┬──────────────────┬─────────┬──────┘
     │                  │         │
     │                  │    ┌────▼──────┐
     │                  │    │  Qdrant   │
     │                  │    │ (Vectors) │
     │                  │    └────▲──────┘
     │                  │         │
┌────▼────────┐    ┌────▼─────────┴──────┐
│  Java App   │    │      Ollama         │
│(Spring Boot)│    │  ┌──────────────┐   │
└────┬────────┘    │  │ Gemma 2B     │   │
     │             │  │ (Chat/Log)   │   │
┌────▼────────┐    │  └──────────────┘   │
│ PostgreSQL  │    │  ┌──────────────┐   │
└────┬────────┘    │  │ nomic-embed  │   │
     │             │  │ (Embeddings) │   │
┌────▼────────┐    │  └──────────────┘   │
│   Health    │    └─────────────────────┘
│  Checker    │
│ (CronJob)   │
└─────────────┘
```

## Prerequisites

- Minikube installed and running
- kubectl configured
- Docker installed
- At least 8GB RAM available for Minikube
- At least 10GB free disk space

## Quick Start

### 1. Start Minikube

```bash
minikube start --memory=8192 --cpus=4
```

### 2. Deploy the POC

```bash
./deploy.sh
```

This script will:
- Build all Docker images
- Create Kubernetes namespace
- Deploy PostgreSQL, Qdrant, Ollama, Java app, health checker, and dashboard
- Pull Ollama models:
  - Gemma 2B (1.7 GB) - for chat and log analysis
  - nomic-embed-text (274 MB) - for RAG embeddings

**Note:** Initial deployment may take 10-15 minutes depending on your internet speed (downloading ~2 GB of AI models).

### 3. Access the Dashboard

After deployment completes, the script will show the dashboard URL. Alternatively:

```bash
minikube service dashboard-service -n failure-monitoring
```

This will open the dashboard in your browser.

## Features

### Failure Types

The Java application supports the following failure scenarios:

1. **HTTP 500 Error** - Returns Internal Server Error
2. **HTTP 503 Service Unavailable** - Returns Service Unavailable
3. **Timeout** - Request hangs for 60 seconds
4. **Exception** - Throws NullPointerException
5. **Memory Leak** - Allocates 10MB every second
6. **CPU Spike** - Creates busy loops consuming CPU

### Dashboard Features

#### Monitoring Tab
- **Real-time Status** - Current application health status
- **Failure Controls** - Trigger/clear failures with button clicks
- **AI-Analyzed Errors** - One-sentence summaries of failures
- **Health History** - Recent health check results
- **Auto-refresh** - Updates every 10 seconds

#### AI Chat Tab
- **Interactive Chat** - Talk directly with local AI (Gemma 2B)
- **Conversation History** - Maintains chat context
- **RAG-Enhanced** - Uses uploaded documents for accurate answers
- **Source Indicators** - Shows when knowledge base is used
- **100% Private** - All processing happens locally

#### Knowledge Base Tab
- **Document Upload** - Add .txt, .md files or paste content
- **Automatic Chunking** - Splits documents into semantic chunks
- **Vector Embeddings** - Converts text to searchable vectors
- **Document Management** - View and delete uploaded documents
- **Chunk Preview** - See how documents are stored

### Health Checker

- Runs every 5 minutes (configurable in k8s-manifests/04-health-checker.yaml)
- Fetches application logs from Kubernetes
- Uses Ollama AI to analyze failures
- Stores results in PostgreSQL

## Usage Examples

### Trigger a Failure

1. Open the dashboard in your browser
2. Click "Trigger" button next to any failure type (e.g., "HTTP 500 Error")
3. Wait for the next health check (up to 5 minutes)
4. View the AI-analyzed error summary in the dashboard

### Manual Health Check

To run a health check immediately without waiting:

```bash
kubectl create job --from=cronjob/health-checker manual-check -n failure-monitoring
```

### View Logs

**Java App:**
```bash
kubectl logs -f deployment/failure-app -n failure-monitoring
```

**Health Checker:**
```bash
kubectl logs -f job/manual-check -n failure-monitoring
```

**Dashboard:**
```bash
kubectl logs -f deployment/dashboard -n failure-monitoring
```

### Clear All Failures

Click the "Clear All Failures" button in the dashboard, or use the API:

```bash
kubectl exec -n failure-monitoring deployment/failure-app -- \
  curl -X POST http://localhost:8080/api/failure/clear-all
```

## AI Chat & Knowledge Base (RAG)

This POC includes a complete **Retrieval-Augmented Generation (RAG)** system that allows the AI to learn from custom documents you upload.

### How RAG Works

1. **Upload Documents** - Add documentation, guides, or knowledge to the Knowledge Base tab
2. **Automatic Indexing** - Documents are split into chunks and converted to vector embeddings
3. **Semantic Search** - When you ask questions, relevant document chunks are retrieved
4. **Enhanced Responses** - AI answers using both its training and your uploaded documents

### Using the AI Chat

1. Navigate to the **AI Chat** tab in the dashboard
2. Type questions about:
   - The failure monitoring system
   - Uploaded documentation
   - General technical topics
3. The AI will show a source indicator when using uploaded documents:
   ```
   📚 Used 3 documents from knowledge base
   ```

### Uploading Knowledge Documents

1. Go to the **Knowledge Base** tab
2. Enter a document title (e.g., "Deployment Guide")
3. Either:
   - **Paste content** directly into the textarea
   - **Upload a file** (.txt or .md)
4. Click "Upload to Knowledge Base"
5. The document is automatically:
   - Split into semantic chunks
   - Converted to 768-dimensional vectors using `nomic-embed-text` model
   - Stored in Qdrant vector database

### Example: Upload Deployment Knowledge

```
Title: Deployment Best Practices

Content:
When deploying to Kubernetes, always follow these steps:

1. Build images with eval $(minikube docker-env)
2. Apply manifests in order (namespace, postgres, ollama, app, checker, dashboard)
3. Wait for Ollama pod to be ready before pulling models
4. Pull both gemma:2b and nomic-embed-text models
5. Verify all pods are running with kubectl get pods

For troubleshooting, check pod logs and events.
```

Then ask in the chat: "What are the deployment best practices?"

The AI will use your uploaded document to provide an accurate, context-specific answer.

### Privacy & Local Processing

- **100% Local:** All AI processing happens on your machine
- **No External Calls:** Embeddings and chat run through Ollama
- **Data Control:** Delete the knowledge base anytime
- **Persistent Storage:** Documents survive pod restarts

### RAG Architecture Components

1. **Qdrant** - Vector database for storing embeddings
   - Port: 6333 (REST API)
   - Storage: 1Gi PersistentVolume
   - Collection: `knowledge_base`

2. **nomic-embed-text** - Embedding model (274 MB)
   - Generates 768-dimensional vectors
   - ~100-200ms per chunk

3. **Vector Search** - Cosine similarity search
   - Retrieves top 3 most relevant chunks
   - Adds context to AI prompts

For detailed RAG implementation, see [RAG-IMPLEMENTATION.md](./RAG-IMPLEMENTATION.md).

## API Endpoints

### Java Application (Port 8080)

- `GET /api/health` - Health check endpoint
- `GET /api/test` - Simple test endpoint
- `POST /api/failure/trigger/{type}` - Trigger a failure
- `POST /api/failure/clear/{type}` - Clear a failure
- `POST /api/failure/clear-all` - Clear all failures
- `GET /api/failure/status` - Get current failure states

### Dashboard Backend (Port 3001)

#### Monitoring Endpoints
- `GET /api/status` - Get current app status
- `GET /api/health-checks` - Get health check history
- `GET /api/health-checks/latest` - Get latest health check
- `POST /api/trigger-failure/:type` - Trigger failure (proxies to Java app)
- `POST /api/clear-failure/:type` - Clear failure (proxies to Java app)

#### AI Chat Endpoints
- `POST /api/chat` - Send message to AI with conversation history
  ```json
  {
    "message": "Your question",
    "history": [{"role": "user", "content": "..."}]
  }
  ```

#### Knowledge Base Endpoints (RAG)
- `POST /api/documents/upload` - Upload document to knowledge base
  ```json
  {
    "title": "Document Title",
    "content": "Document content...",
    "metadata": {"source": "user_upload"}
  }
  ```
- `GET /api/documents` - List all uploaded documents
- `DELETE /api/documents/all` - Clear entire knowledge base

## Database Schema

### health_checks

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| timestamp | TIMESTAMP | When the check occurred |
| status | VARCHAR(20) | 'healthy' or 'unhealthy' |
| error_summary | TEXT | AI-generated summary |
| raw_logs | TEXT | Raw application logs |

### app_status

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Always 1 (single row) |
| current_status | VARCHAR(20) | Current status |
| last_check_time | TIMESTAMP | Last check timestamp |
| failure_count | INTEGER | Total failure count |

## Troubleshooting

### Ollama model not loading

If the Gemma model fails to load:

```bash
kubectl exec -n failure-monitoring deployment/ollama -- ollama pull gemma:2b
```

### Pods not starting

Check pod status:

```bash
kubectl get pods -n failure-monitoring
```

View pod details:

```bash
kubectl describe pod <pod-name> -n failure-monitoring
```

### Dashboard not accessible

Get the dashboard URL:

```bash
minikube service dashboard-service -n failure-monitoring --url
```

If using Docker Desktop on Mac/Windows, you may need to use port-forward:

```bash
kubectl port-forward -n failure-monitoring service/dashboard-service 3001:3001
```

Then access: http://localhost:3001

### Health checker failing

Check CronJob status:

```bash
kubectl get cronjobs -n failure-monitoring
kubectl get jobs -n failure-monitoring
```

View recent job logs:

```bash
kubectl logs -l job-name=<job-name> -n failure-monitoring
```

### RAG system not working

**Check Qdrant is running:**

```bash
kubectl get pods -n failure-monitoring | grep qdrant
kubectl logs -n failure-monitoring deployment/qdrant
```

**Verify embedding model is available:**

```bash
kubectl exec -n failure-monitoring deployment/ollama -- ollama list
# Should show both gemma:2b and nomic-embed-text
```

**If model is missing, pull it:**

```bash
kubectl exec -n failure-monitoring deployment/ollama -- ollama pull nomic-embed-text
```

**Check if documents are stored:**

```bash
# Get collection info
kubectl exec -n failure-monitoring deployment/qdrant -- \
  wget -qO- http://localhost:6333/collections/knowledge_base
```

**Test document upload manually:**

```bash
# Port-forward dashboard
kubectl port-forward -n failure-monitoring service/dashboard-service 3001:3001

# Upload test document
curl -X POST http://localhost:3001/api/documents/upload \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"This is a test document about Kubernetes deployment."}'
```

## Customization

### Change Health Check Frequency

Edit `k8s-manifests/04-health-checker.yaml`:

```yaml
spec:
  schedule: "*/5 * * * *"  # Change to desired cron expression
```

Apply changes:

```bash
kubectl apply -f k8s-manifests/04-health-checker.yaml
```

### Use Different AI Model

Edit `health-checker/health_checker.py`:

```python
"model": "gemma:2b",  # Change to another Ollama model
```

Rebuild and redeploy:

```bash
eval $(minikube docker-env)
docker build -t health-checker:latest ./health-checker
kubectl rollout restart deployment/health-checker -n failure-monitoring
```

### Adjust Resource Limits

Edit the respective YAML files in `k8s-manifests/` to change resource requests/limits.

## Cleanup

To remove all resources:

```bash
./cleanup.sh
```

This will delete the entire `failure-monitoring` namespace and all resources.

## Project Structure

```
.
├── dashboard/
│   ├── backend/          # Node.js Express API with RAG
│   │   └── server.js     # Includes vector search & embeddings
│   ├── frontend/         # React application
│   │   └── src/
│   │       ├── App.js    # Main app with tabs
│   │       ├── Chat.js   # AI chat interface
│   │       └── Documents.js  # Knowledge base UI
│   └── Dockerfile
├── health-checker/
│   ├── health_checker.py # Python health check script
│   ├── requirements.txt
│   └── Dockerfile
├── java-app/
│   ├── src/             # Spring Boot application
│   ├── pom.xml
│   └── Dockerfile
├── k8s-manifests/       # Kubernetes YAML files
│   ├── 00-namespace.yaml
│   ├── 01-postgres.yaml
│   ├── 02-ollama.yaml
│   ├── 03-java-app.yaml
│   ├── 04-health-checker.yaml
│   ├── 05-dashboard.yaml
│   └── 06-qdrant.yaml   # Vector database for RAG
├── postgres-init/
│   └── init.sql
├── deploy.sh
├── cleanup.sh
├── README.md
├── RAG-IMPLEMENTATION.md  # Detailed RAG documentation
└── suggestions-to-improve.md  # Future enhancements
```

## Technical Details

### Technologies Used

- **Backend:** Spring Boot 3.2, Node.js, Python 3.11
- **Frontend:** React 18
- **Database:** PostgreSQL 14 (relational), Qdrant (vector)
- **AI:** Ollama with:
  - Gemma 2B (1.7 GB) - Chat and log analysis
  - nomic-embed-text (274 MB) - Document embeddings
- **RAG:** Vector search with semantic chunking
- **Container:** Docker
- **Orchestration:** Kubernetes (Minikube)

### Security Notes

This is a POC for local development only. For production use:

- Use Secrets for database credentials
- Enable authentication on all services
- Use HTTPS/TLS
- Implement proper RBAC
- Use network policies
- Scan images for vulnerabilities

## License

This is a proof-of-concept project for demonstration purposes.

## Support

For issues or questions, please check:
- Kubernetes pod logs
- Minikube status
- Resource availability (RAM, CPU, disk)
