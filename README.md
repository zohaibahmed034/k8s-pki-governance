
# Kubernetes PKI Implementation project 🔐☸️

This project demonstrates how to implement a complete **Public Key Infrastructure (PKI)** for Kubernetes cluster components using custom Certificate Authorities (CA), TLS certificates, certificate rotation, monitoring, and verification scripts.

The goal is to secure communication between Kubernetes components such as:

- Kubernetes API Server
- etcd
- kubelet
- Admin clients

---

## 📌 Project Objectives

By completing this project, you will learn how to:

- Understand PKI fundamentals in Kubernetes
- Set up a custom Certificate Authority (CA)
- Generate TLS certificates for Kubernetes components
- Implement certificate rotation for security maintenance
- Monitor certificate expiration automatically
- Verify secure TLS communication between cluster components
- Troubleshoot PKI-related issues in Kubernetes

---

## 🏗️ Project Architecture

```bash
k8s-pki/
├── ca/
│   ├── private/
│   └── certs/
├── api-server/
│   ├── private/
│   └── certs/
├── etcd/
│   ├── private/
│   └── certs/
├── kubelet/
│   ├── private/
│   └── certs/
├── certs/
├── keys/
├── csr/
├── rotate-certificates.sh
├── monitor-certificates.sh
├── verify-certificates.sh
├── test-auth.sh
└── test-tls-communication.sh
```

---

## ⚙️ Technologies Used

- Kubernetes
- OpenSSL
- Linux (Ubuntu 20.04)
- Bash Scripting
- Cron Jobs
- TLS/SSL Certificates
- PKI Concepts

---

## 🔐 Features Implemented

### 1. Custom Certificate Authority (CA)
- Generated root CA private key
- Created root CA certificate
- Signed all Kubernetes component certificates

### 2. Kubernetes Component Certificates
Generated certificates for:

- kube-apiserver
- etcd
- kubelet
- admin client

### 3. Certificate Rotation
Implemented automated certificate rotation using:

```bash
rotate-certificates.sh
```

Capabilities:
- Backup old certificates
- Generate new certificates
- Replace expiring certificates
- Maintain secure permissions

### 4. Certificate Monitoring
Implemented automated certificate health checks:

```bash
monitor-certificates.sh
```

Capabilities:
- Check expiration dates
- Alert for certificates expiring within 30 days
- Log certificate health status

### 5. Automated Scheduling
Configured cron job for daily certificate monitoring:

```bash
0 9 * * * $HOME/k8s-pki/monitor-certificates.sh
```

### 6. Certificate Verification
Verification script validates:

- Certificate signatures
- CA trust chain
- Private key matching
- Subject Alternative Names (SAN)

```bash
verify-certificates.sh
```

### 7. Authentication Testing
Tested certificate-based client authentication:

```bash
test-auth.sh
```

Includes:
- Admin authentication
- Kubelet authentication
- Kubeconfig generation

### 8. TLS Communication Testing
Simulated secure TLS communication between services:

```bash
test-tls-communication.sh
```

---

## 🚀 How to Run

### Clone Repository

```bash
git clone https://github.com/yourusername/kubernetes-pki-lab.git
cd kubernetes-pki-lab
```

### Run Certificate Monitoring

```bash
./monitor-certificates.sh
```

### Rotate Certificates

```bash
./rotate-certificates.sh
```

### Verify Certificates

```bash
./verify-certificates.sh
```

### Test Authentication

```bash
./test-auth.sh
```

---

## 📚 Learning Outcomes

This project helped me understand:

- Kubernetes internal security architecture
- TLS certificate lifecycle management
- Custom CA creation
- Certificate signing requests (CSR)
- Certificate rotation strategies
- Production-grade cluster security practices

---

## 💡 Real-World Use Cases

This implementation is useful in:

- Secure Kubernetes production clusters
- Zero Trust Kubernetes environments
- Internal enterprise PKI systems
- DevSecOps pipelines
- Compliance-focused infrastructure

---

## 👨‍💻 Author

**Zohaib Ahmed**  
DevOps | Kubernetes | DevSecOps | Cloud Security Enthusiast
