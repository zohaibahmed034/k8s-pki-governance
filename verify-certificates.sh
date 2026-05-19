#!/bin/bash

# Certificate verification script
PKI_DIR="$HOME/k8s-pki"

echo "=== Kubernetes PKI Certificate Verification ==="
echo

# Function to verify certificate against CA
verify_certificate() {
    local cert_file="$1"
    local cert_name="$2"
    local ca_file="$PKI_DIR/ca/certs/ca.pem"
    
    echo "Verifying $cert_name certificate..."
    
    if [ ! -f "$cert_file" ]; then
        echo "  ERROR: Certificate file not found: $cert_file"
        return 1
    fi
    
    # Verify certificate against CA
    if openssl verify -CAfile "$ca_file" "$cert_file" >/dev/null 2>&1; then
        echo "  ✓ Certificate is valid and signed by our CA"
    else
        echo "  ✗ Certificate verification failed"
        return 1
    fi
    
    # Display certificate details
    echo "  Certificate Details:"
    echo "    Subject: $(openssl x509 -in "$cert_file" -noout -subject | sed 's/subject=//')"
    echo "    Issuer: $(openssl x509 -in "$cert_file" -noout -issuer | sed 's/issuer=//')"
    echo "    Valid From: $(openssl x509 -in "$cert_file" -noout -startdate | sed 's/notBefore=//')"
    echo "    Valid Until: $(openssl x509 -in "$cert_file" -noout -enddate | sed 's/notAfter=//')"
    
    # Check Subject Alternative Names for server certificates
    if openssl x509 -in "$cert_file" -noout -ext subjectAltName >/dev/null 2>&1; then
        echo "    Subject Alternative Names:"
        openssl x509 -in "$cert_file" -noout -ext subjectAltName | grep -A 10 "X509v3 Subject Alternative Name:" | tail -n +2 | sed 's/^/      /'
    fi
    
    echo
    return 0
}

# Function to test certificate chain
test_certificate_chain() {
    local server_cert="$1"
    local server_key="$2"
    local ca_cert="$3"
    local test_name="$4"
    
    echo "Testing certificate chain for $test_name..."
    
    # Create a temporary server configuration
    local temp_config=$(mktemp)
    cat > "$temp_config" << EOL
[req]
distinguished_name = req_distinguished_name

[req_distinguished_name]
EOL
    
    # Test if private key matches certificate
    local cert_modulus=$(openssl x509 -noout -modulus -in "$server_cert" 2>/dev/null | openssl md5)
    local key_modulus=$(openssl rsa -noout -modulus -in "$server_key" 2>/dev/null | openssl md5)
    
    if [ "$cert_modulus" = "$key_modulus" ]; then
        echo "  ✓ Private key matches certificate"
    else
        echo "  ✗ Private key does not match certificate"
        rm -f "$temp_config"
        return 1
    fi
    
    # Verify certificate chain
    if openssl verify -CAfile "$ca_cert" "$server_cert" >/dev/null 2>&1; then
        echo "  ✓ Certificate chain is valid"
    else
        echo "  ✗ Certificate chain verification failed"
        rm -f "$temp_config"
        return 1
    fi
    
    rm -f "$temp_config"
    echo
    return 0
}

# Verify CA certificate
echo "1. Verifying Root CA Certificate"
echo "================================"
if [ -f "$PKI_DIR/ca/certs/ca.pem" ]; then
    echo "CA Certificate Details:"
    echo "  Subject: $(openssl x509 -in "$PKI_DIR/ca/certs/ca.pem" -noout -subject | sed 's/subject=//')"
    echo "  Valid From: $(openssl x509 -in "$PKI_DIR/ca/certs/ca.pem" -noout -startdate | sed 's/notBefore=//')"
    echo "  Valid Until: $(openssl x509 -in "$PKI_DIR/ca/certs/ca.pem" -noout -enddate | sed 's/notAfter=//')"
    echo "  ✓ Root CA certificate found and readable"
else
    echo "  ✗ Root CA certificate not found"
    exit 1
fi
echo

# Verify individual certificates
echo "2. Verifying Individual Certificates"
echo "===================================="
verify_certificate "$PKI_DIR/api-server/certs/api-server.pem" "API Server"
verify_certificate "$PKI_DIR/etcd/certs/etcd.pem" "etcd"
verify_certificate "$PKI_DIR/certs/admin.pem" "Admin Client"
verify_certificate "$PKI_DIR/kubelet/certs/kubelet.pem" "Kubelet"

# Test certificate chains
echo "3. Testing Certificate Chains"
echo "============================="
test_certificate_chain "$PKI_DIR/api-server/certs/api-server.pem" "$PKI_DIR/api-server/private/api-server-key.pem" "$PKI_DIR/ca/certs/ca.pem" "API Server"
test_certificate_chain "$PKI_DIR/etcd/certs/etcd.pem" "$PKI_DIR/etcd/private/etcd-key.pem" "$PKI_DIR/ca/certs/ca.pem" "etcd"

echo "Certificate verification completed!"
