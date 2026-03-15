#!/bin/bash

echo "=========================================="
echo "Accessing Failure Monitoring Dashboard"
echo "=========================================="
echo ""

# Check if minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo "Error: Minikube is not running. Please start minikube first with 'minikube start'"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace failure-monitoring > /dev/null 2>&1; then
    echo "Error: Namespace 'failure-monitoring' not found. Please run ./deploy.sh first"
    exit 1
fi

echo "Port-forwarding dashboard to http://localhost:3001"
echo ""
echo "The dashboard will be accessible at: http://localhost:3001"
echo ""
echo "Press Ctrl+C to stop the port-forward"
echo ""

kubectl port-forward -n failure-monitoring service/dashboard-service 3001:3001
