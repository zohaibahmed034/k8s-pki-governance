#!/bin/bash

# Certificate rotation script for Kubernetes components
set -e

PKI_DIR="$HOME/k8s-pki"
BACKUP_DIR="$PKI_DIR/backup-$(date +%Y%m%d-%H%M%S)"

echo "Starting certificate rotation process..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup existing certificates
backup_certificates() {
    echo "Backing up existing certificates..."
    cp -r "$PKI_DIR/api-server/certs" "$BACKUP_DIR/api-server-certs"
    cp -r "$PKI_DIR/etcd/certs" "$BACKUP_DIR/etcd-certs"
    cp -r "$PKI_DIR/certs" "$BACKUP_DIR/client-certs"
    echo "Backup completed in $BACKUP_DIR"
}

# Function to check certificate expiration
check_certificate_expiration() {
    local cert_file="$1"
    local cert_name="$2"
    
    if [ -f "$cert_file" ]; then
        local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry_date" +%s)
        local current_epoch=$(date +%s)
        local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
        
        echo "$cert_name expires in $days_until_expiry days ($expiry_date)"
        
        if [ $days_until_expiry -lt 30 ]; then
            echo "WARNING: $cert_name expires in less than 30 days!"
            return 1
        fi
    else
        echo "Certificate file $cert_file not found!"
        return 1
    fi
    return 0
}

# Function to rotate API server certificate
rotate_api_server_cert() {
    echo "Rotating API server certificate..."
    
    # Generate new private key
    openssl genrsa -out "$PKI_DIR/api-server/private/api-server-key-new.pem" 2048
    
    # Generate new certificate
    openssl req -new -key "$PKI_DIR/api-server/private/api-server-key-new.pem" -out "$PKI_DIR/api-server/api-server-new.csr" -config <(
cat << EOL
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = system:masters
OU = Kubernetes The Hard Way
CN = kube-apiserver

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = localhost
IP.1 = 127.0.0.1
IP.2 = 10.96.0.1
EOL
)
    
    # Sign new certificate
    openssl x509 -req -in "$PKI_DIR/api-server/api-server-new.csr" -CA "$PKI_DIR/ca/certs/ca.pem" -CAkey "$PKI_DIR/ca/private/ca-key.pem" -CAcreateserial -out "$PKI_DIR/api-server/certs/api-server-new.pem" -days 365 -extensions v3_req -extfile <(
cat << EOL
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = localhost
IP.1 = 127.0.0.1
IP.2 = 10.96.0.1
EOL
)
    
    # Replace old certificates with new ones
    mv "$PKI_DIR/api-server/private/api-server-key.pem" "$PKI_DIR/api-server/private/api-server-key-old.pem"
    mv "$PKI_DIR/api-server/certs/api-server.pem" "$PKI_DIR/api-server/certs/api-server-old.pem"
    mv "$PKI_DIR/api-server/private/api-server-key-new.pem" "$PKI_DIR/api-server/private/api-server-key.pem"
    mv "$PKI_DIR/api-server/certs/api-server-new.pem" "$PKI_DIR/api-server/certs/api-server.pem"
    
    # Set proper permissions
    chmod 400 "$PKI_DIR/api-server/private/api-server-key.pem"
    
    echo "API server certificate rotated successfully"
}

# Main execution
backup_certificates

# Check certificate expiration
echo "Checking certificate expiration..."
check_certificate_expiration "$PKI_DIR/api-server/certs/api-server.pem" "API Server"
api_server_needs_rotation=$?

check_certificate_expiration "$PKI_DIR/etcd/certs/etcd.pem" "etcd"
etcd_needs_rotation=$?

# Rotate certificates if needed
if [ $api_server_needs_rotation -ne 0 ]; then
    rotate_api_server_cert
fi

echo "Certificate rotation process completed!"
