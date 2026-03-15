# Quick Start Guide

## 🚀 Initial Setup

### 1. Start Minikube
```bash
minikube start --memory=7168 --cpus=4
```

### 2. Deploy Everything
```bash
./deploy.sh
```

This will:
- Build all Docker images
- Deploy PostgreSQL, Qdrant, Ollama, Java app, health checker, and dashboard
- Pull AI models (Gemma 2B and nomic-embed-text)
- Takes ~10-15 minutes on first run

## 📊 Access Dashboard

### Option 1: Simple Script (Recommended)
```bash
./access-dashboard.sh
```

Then open your browser to: **http://localhost:3001**

### Option 2: Manual Port-Forward
```bash
kubectl port-forward -n failure-monitoring service/dashboard-service 3001:3001
```

Then open: **http://localhost:3001**

### Option 3: Minikube Service
```bash
minikube service dashboard-service -n failure-monitoring
```

## 🎯 Using the Dashboard

The dashboard has 3 tabs (always visible at the top):

### 📊 Monitoring Tab
- View current application status
- Trigger/clear failures (6 types: HTTP 500, 503, timeout, exception, memory leak, CPU spike)
- See AI-analyzed error summaries
- View health check history

### 💬 AI Chat Tab
- Chat with local AI (Gemma 2B)
- Ask technical questions
- AI uses uploaded documents for better answers
- Look for 📚 indicator when knowledge base is used

### 📚 Knowledge Base Tab
- Upload documentation (.txt, .md files)
- Paste content directly
- View uploaded documents
- Delete all documents

## 📝 Example Workflow

1. **Upload Documentation**
   - Go to Knowledge Base tab
   - Upload your deployment guide or docs
   - Click "Upload to Knowledge Base"

2. **Ask Questions**
   - Go to AI Chat tab
   - Ask: "How do I deploy this application?"
   - AI will use your uploaded docs to answer

3. **Monitor Application**
   - Go to Monitoring tab
   - Trigger a failure (e.g., HTTP 500)
   - Wait up to 5 minutes for health check
   - See AI-analyzed error summary

## 🔧 Useful Commands

### Check All Pods
```bash
kubectl get pods -n failure-monitoring
```

### View Logs
```bash
# Dashboard logs
kubectl logs -f deployment/dashboard -n failure-monitoring

# Java app logs
kubectl logs -f deployment/failure-app -n failure-monitoring

# Ollama logs
kubectl logs -f deployment/ollama -n failure-monitoring
```

### Manual Health Check
```bash
kubectl create job --from=cronjob/health-checker manual-check -n failure-monitoring
```

### Check Ollama Models
```bash
kubectl exec -n failure-monitoring deployment/ollama -- ollama list
```

### Restart Dashboard
```bash
kubectl rollout restart deployment/dashboard -n failure-monitoring
```

## 🧹 Cleanup

Remove everything:
```bash
./cleanup.sh
```

## 🐛 Troubleshooting

### Dashboard Not Accessible
1. Check pods are running:
   ```bash
   kubectl get pods -n failure-monitoring
   ```

2. Restart port-forward:
   ```bash
   ./access-dashboard.sh
   ```

### Chat Returns Network Error
- Dashboard needs port-forwarding on macOS with Docker Desktop
- Use `./access-dashboard.sh` instead of direct NodePort access

### RAG Not Working
1. Check Qdrant is running:
   ```bash
   kubectl get pods -n failure-monitoring | grep qdrant
   ```

2. Check models are loaded:
   ```bash
   kubectl exec -n failure-monitoring deployment/ollama -- ollama list
   ```
   Should show: `gemma:2b` and `nomic-embed-text`

### Health Checker Not Running
```bash
# View cronjob
kubectl get cronjobs -n failure-monitoring

# Trigger manual check
kubectl create job --from=cronjob/health-checker manual-check -n failure-monitoring
```

## 📚 Documentation

- **README.md** - Complete documentation
- **RAG-IMPLEMENTATION.md** - Detailed RAG system guide
- **suggestions-to-improve.md** - Future enhancements

## 🎓 Key Features

✅ **100% Local** - All AI runs on your machine (Ollama)
✅ **Private** - No data leaves your cluster
✅ **RAG System** - Upload docs to teach the AI
✅ **AI Error Analysis** - Automatic log analysis with actionable fixes
✅ **Failure Simulation** - Test 6 different failure scenarios
✅ **Auto Health Checks** - Every 5 minutes
