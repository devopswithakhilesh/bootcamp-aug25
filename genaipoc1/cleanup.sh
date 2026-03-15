#!/bin/bash

echo "=========================================="
echo "Failure Monitoring POC - Cleanup Script"
echo "=========================================="
echo ""

echo "Deleting all resources in failure-monitoring namespace..."
kubectl delete namespace failure-monitoring

echo ""
echo "Cleanup completed successfully!"
echo "All resources have been removed."
echo ""
