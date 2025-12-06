#!/bin/bash
# Initialize MongoDB Replica Set on container startup
# This script runs the MongoDB daemon and initializes the replica set if needed

# Don't exit on error
set +e

echo "[MongoDB Init] Starting MongoDB daemon in background..."
mongod --oplogSize 128 --replSet rs0 --bind_ip_all --port 27017 &
MONGO_PID=$!

echo "[MongoDB Init] Waiting for MongoDB to be ready..."
READY=0
for i in {1..60}; do
    if mongosh --eval "db.runCommand('ping')" > /dev/null 2>&1; then
        echo "[MongoDB Init] MongoDB is ready"
        READY=1
        break
    fi
    echo "[MongoDB Init] Attempt $i/60 - waiting for MongoDB..."
    sleep 1
done

if [ $READY -eq 1 ]; then
    echo "[MongoDB Init] Checking replica set status..."
    STATUS=$(mongosh --eval "rs.status().ok" 2>/dev/null || echo "0")
    
    if [ "$STATUS" != "1" ]; then
        echo "[MongoDB Init] Initializing replica set..."
        mongosh --eval "rs.initiate()" 2>&1
        echo "[MongoDB Init] Replica set initialization requested"
    else
        echo "[MongoDB Init] Replica set already initialized"
    fi
else
    echo "[MongoDB Init] WARNING: MongoDB did not start properly"
fi

echo "[MongoDB Init] Setup complete - MongoDB daemon running with PID $MONGO_PID"

# Keep the process running in foreground
wait $MONGO_PID
