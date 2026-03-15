# Quick Reference Guide

## Deployment Commands

```bash
# Start Minikube
minikube start --memory=8192 --cpus=4

# Deploy the POC
./deploy.sh

# Access dashboard
minikube service dashboard-service -n failure-monitoring

# Cleanup everything
./cleanup.sh
```

## Monitoring Commands

```bash
# View all pods
kubectl get pods -n failure-monitoring

# View all services
kubectl get svc -n failure-monitoring

# View CronJob status
kubectl get cronjobs -n failure-monitoring

# View recent jobs
kubectl get jobs -n failure-monitoring

# Watch pod status in real-time
kubectl get pods -n failure-monitoring -w
```

## Log Commands

```bash
# Java app logs
kubectl logs -f deployment/failure-app -n failure-monitoring

# Dashboard logs
kubectl logs -f deployment/dashboard -n failure-monitoring

# Ollama logs
kubectl logs -f deployment/ollama -n failure-monitoring

# PostgreSQL logs
kubectl logs -f deployment/postgres -n failure-monitoring

# Health checker logs (latest job)
kubectl logs -l app=health-checker -n failure-monitoring --tail=100

# Follow health checker logs
kubectl logs -f job/<job-name> -n failure-monitoring
```

## Manual Testing

```bash
# Run manual health check
kubectl create job --from=cronjob/health-checker manual-check-$(date +%s) -n failure-monitoring

# Test Java app health endpoint
kubectl exec -n failure-monitoring deployment/failure-app -- \
  curl http://localhost:8080/api/health

# Test dashboard backend
kubectl exec -n failure-monitoring deployment/dashboard -- \
  curl http://localhost:3001/api/status

# Trigger HTTP 500 failure via CLI
kubectl exec -n failure-monitoring deployment/failure-app -- \
  curl -X POST http://localhost:8080/api/failure/trigger/http_500

# Clear all failures via CLI
kubectl exec -n failure-monitoring deployment/failure-app -- \
  curl -X POST http://localhost:8080/api/failure/clear-all
```

## Database Access

```bash
# Connect to PostgreSQL
kubectl exec -it deployment/postgres -n failure-monitoring -- \
  psql -U postgres -d failuredb

# View health checks
kubectl exec -it deployment/postgres -n failure-monitoring -- \
  psql -U postgres -d failuredb -c "SELECT * FROM health_checks ORDER BY timestamp DESC LIMIT 10;"

# View app status
kubectl exec -it deployment/postgres -n failure-monitoring -- \
  psql -U postgres -d failuredb -c "SELECT * FROM app_status;"
```

## Troubleshooting

```bash
# Describe pod for issues
kubectl describe pod <pod-name> -n failure-monitoring

# Check pod events
kubectl get events -n failure-monitoring --sort-by='.lastTimestamp'

# Restart a deployment
kubectl rollout restart deployment/<deployment-name> -n failure-monitoring

# Check resource usage
kubectl top pods -n failure-monitoring

# Port forward to access services locally
kubectl port-forward -n failure-monitoring service/dashboard-service 3001:3001
kubectl port-forward -n failure-monitoring service/failure-app-service 8080:8080

# Get Minikube IP
minikube ip

# SSH into Minikube
minikube ssh
```

## Ollama Management

```bash
# List Ollama models
kubectl exec -n failure-monitoring deployment/ollama -- ollama list

# Pull a model
kubectl exec -n failure-monitoring deployment/ollama -- ollama pull gemma:2b

# Remove a model
kubectl exec -n failure-monitoring deployment/ollama -- ollama rm gemma:2b

# Test Ollama directly
kubectl exec -n failure-monitoring deployment/ollama -- \
  curl http://localhost:11434/api/generate -d '{
    "model": "gemma:2b",
    "prompt": "Hello, world!",
    "stream": false
  }'
```

## Rebuilding Images

```bash
# Set Docker environment to Minikube
eval $(minikube docker-env)

# Rebuild Java app
docker build -t failure-app:latest ./java-app
kubectl rollout restart deployment/failure-app -n failure-monitoring

# Rebuild health checker
docker build -t health-checker:latest ./health-checker
# CronJob will use new image on next run

# Rebuild dashboard
docker build -t dashboard:latest ./dashboard
kubectl rollout restart deployment/dashboard -n failure-monitoring
```

## Scaling

```bash
# Scale Java app
kubectl scale deployment/failure-app --replicas=2 -n failure-monitoring

# Scale dashboard
kubectl scale deployment/dashboard --replicas=2 -n failure-monitoring

# Check current replicas
kubectl get deployment -n failure-monitoring
```

## CronJob Management

```bash
# Suspend CronJob (stop automatic runs)
kubectl patch cronjob health-checker -n failure-monitoring -p '{"spec":{"suspend":true}}'

# Resume CronJob
kubectl patch cronjob health-checker -n failure-monitoring -p '{"spec":{"suspend":false}}'

# Change schedule to every minute (for testing)
kubectl patch cronjob health-checker -n failure-monitoring -p '{"spec":{"schedule":"*/1 * * * *"}}'

# Delete old jobs
kubectl delete job -l app=health-checker -n failure-monitoring
```

## Dashboard URLs (NodePort)

```bash
# Get dashboard URL
minikube service dashboard-service -n failure-monitoring --url

# Or construct manually
echo "http://$(minikube ip):30001"
```

## Useful One-Liners

```bash
# Watch all pods status
watch kubectl get pods -n failure-monitoring

# Get all container images in use
kubectl get pods -n failure-monitoring -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}'

# Check if all deployments are ready
kubectl get deployments -n failure-monitoring

# Delete all failed jobs
kubectl delete jobs --field-selector status.successful=0 -n failure-monitoring

# Get pod resource usage
kubectl top pods -n failure-monitoring --containers
```

## Emergency Reset

```bash
# Delete namespace and redeploy
./cleanup.sh
./deploy.sh

# Or just restart all deployments
kubectl rollout restart deployment --all -n failure-monitoring
```
