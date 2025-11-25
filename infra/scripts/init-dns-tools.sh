#!/bin/bash
# Initialize DNS tools in containers
# This script installs dnsutils (bind-tools) synchronously

set -e

echo "Installing DNS tools..."

# Detect the package manager and install accordingly
if command -v apt-get &> /dev/null; then
    apt-get update > /dev/null 2>&1
    apt-get install -y dnsutils > /dev/null 2>&1
elif command -v apk &> /dev/null; then
    apk update > /dev/null 2>&1
    apk add --no-cache bind-tools > /dev/null 2>&1
elif command -v yum &> /dev/null; then
    yum install -y bind-utils > /dev/null 2>&1
fi

echo "DNS tools installed successfully"
