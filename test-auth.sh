#!/bin/bash

# Certificate-based authentication test script
PKI_DIR="$HOME/k8s-pki"

echo "=== Testing Certificate-Based Authentication ==="
echo

# Function to test client certificate authentication
test_client_auth() {
    local client_cert="$1"
    local client_key="$2"
    local ca_cert="$3"
    local client_name="$4"
    
    echo "Testing $client_name certificate authentication..."
    
    # Create a temporary kubeconfig for testing
    local temp_kubeconfig=$(mktemp)
    
    # Note: This is a simulation since we don't have a running cluster
    # In a real environment, you would test against an actual API server
    
    echo "  Certificate Details:"
    echo "    Subject: $(openssl x509 -in "$client_cert" -noout -subject | sed 's/subject=//')"
    
    # Verify the client certificate
    if openssl verify -CAfile "$ca_cert" "$client_cert" >/dev/null 2>&1; then
        echo "  ✓ Client certificate is valid"
    else
        echo "  ✗ Client certificate verification failed"
        rm -f "$temp_kubeconfig"
        return 1
    fi
    
    # Check if private key matches certificate
    local cert_modulus=$(openssl x509 -noout -modulus -in "$client_cert" 2>/dev/null | openssl md5)
    local key_modulus=$(openssl rsa -noout -modulus -in "$client_key" 2>/dev/null | openssl md5)
    
    if [ "$cert_modulus" = "$key_modulus" ]; then
        echo "  ✓ Private key matches certificate"
    else
        echo "  ✗ Private key does not match certificate"
        rm -f "$temp_kubeconfig"
        return 1
    fi
    
    # Create kubeconfig content (for demonstration)
    cat > "$temp_kubeconfig" << EOL
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $(base64 -w 0 "$ca_cert")
    server: https://127.0.0.1:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: $client_name
  name: $client_name@kubernetes
current-context: $client_name@kubernetes
users:
- name: $client_name
  user:
    client-certificate-data: $(base64 -w 0 "$client_cert")
    client-key-data: $(base64 -w 0 "$client_key")
EOL
    
    echo "  ✓ Kubeconfig created successfully"
    echo "  ✓ Certificate-based authentication configuration is valid"
    
    rm -f "$temp_kubeconfig"
    echo
    return 0
}

# Test admin client authentication
test_client_auth "$PKI_DIR/certs/admin.pem" "$PKI_DIR/keys/admin-key.pem" "$PKI_DIR/ca/certs/ca.pem" "admin"

# Test kubelet client authentication
test_client_auth "$PKI_DIR/kubelet/certs/kubelet.pem" "$PKI_DIR/kubelet/private/kubelet-key.pem" "$PKI_DIR/ca/certs/ca.pem" "kubelet"

echo "Authentication testing completed!"
