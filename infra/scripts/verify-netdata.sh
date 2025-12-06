#!/bin/bash
# Verify Netdata Service and Integration

echo "----------------------------------------------------------------"
echo "Starting Netdata Verification..."
echo "----------------------------------------------------------------"

# 1. Check Container Status
echo "Checking Docker container status..."
if docker ps | grep -q "netdata"; then
    echo "✅ Netdata container is running."
else
    echo "❌ Netdata container is NOT running."
    exit 1
fi

# 2. Check Netdata API (Internal)
echo "Checking Netdata API accessibility..."
API_STATUS=$(docker exec netdata curl -s -o /dev/null -w "%{http_code}" http://localhost:19999/api/v1/info)
if [ "$API_STATUS" -eq 200 ]; then
    echo "✅ Netdata API is accessible internally (HTTP 200)."
else
    echo "❌ Netdata API check failed (HTTP $API_STATUS)."
    exit 1
fi

# 3. Check Prometheus Metrics Endpoint
echo "Checking Prometheus metrics endpoint..."
METRICS_Check=$(docker exec netdata curl -s "http://localhost:19999/api/v1/allmetrics?format=prometheus" | grep "netdata_info" | head -n 1)

if [[ ! -z "$METRICS_Check" ]]; then
    echo "✅ Prometheus metrics are being generated."
else
    echo "❌ Failed to retrieve Prometheus metrics."
    exit 1
fi

# 4. Check Config Binding
echo "Checking configuration file..."
if docker exec netdata ls -l /etc/netdata/netdata.conf | grep -q "netdata.conf"; then
    echo "✅ netdata.conf is present in container."
else
    echo "❌ netdata.conf not found."
    exit 1
fi

echo "----------------------------------------------------------------"
echo "Netdata verification completed successfully."
echo "----------------------------------------------------------------"
