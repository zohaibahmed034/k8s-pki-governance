#!/bin/bash

# Certificate monitoring script
PKI_DIR="$HOME/k8s-pki"
LOG_FILE="$PKI_DIR/cert-monitor.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check certificate validity
check_cert_validity() {
    local cert_file="$1"
    local cert_name="$2"
    
    if [ ! -f "$cert_file" ]; then
        log_message "ERROR: Certificate file $cert_file not found"
        return 1
    fi
    
    # Check if certificate is valid
    if ! openssl x509 -in "$cert_file" -noout -checkend 0 >/dev/null 2>&1; then
        log_message "ERROR: Certificate $cert_name has expired"
        return 1
    fi
    
    # Check if certificate expires within 30 days
    if openssl x509 -in "$cert_file" -noout -checkend 2592000 >/dev/null 2>&1; then
        log_message "OK: Certificate $cert_name is valid"
        return 0
    else
        log_message "WARNING: Certificate $cert_name expires within 30 days"
        return 2
    fi
}

# Function to send alert (placeholder for actual alerting mechanism)
send_alert() {
    local message="$1"
    log_message "ALERT: $message"
    # In a real environment, you would integrate with your alerting system
    # Example: curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$message"'"}' YOUR_WEBHOOK_URL
}

# Main monitoring logic
log_message "Starting certificate monitoring check"

# Check all certificates
certificates=(
    "$PKI_DIR/ca/certs/ca.pem:Root CA"
    "$PKI_DIR/api-server/certs/api-server.pem:API Server"
    "$PKI_DIR/etcd/certs/etcd.pem:etcd"
    "$PKI_DIR/certs/admin.pem:Admin Client"
    "$PKI_DIR/kubelet/certs/kubelet.pem:Kubelet"
)

alert_needed=false

for cert_info in "${certificates[@]}"; do
    cert_file="${cert_info%:*}"
    cert_name="${cert_info#*:}"
    
    check_cert_validity "$cert_file" "$cert_name"
    result=$?
    
    if [ $result -eq 1 ]; then
        send_alert "Certificate $cert_name has expired or is invalid"
        alert_needed=true
    elif [ $result -eq 2 ]; then
        send_alert "Certificate $cert_name expires within 30 days"
        alert_needed=true
    fi
done

if [ "$alert_needed" = false ]; then
    log_message "All certificates are valid and not expiring soon"
fi

log_message "Certificate monitoring check completed"
