# 🤖 Stan's Robot Shop — Production-Grade Microservices on AWS EKS

> Deployed, stress-tested, and broken on purpose. This is what a real Kubernetes project looks like.

[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://aws.amazon.com/eks/)
[![Istio](https://img.shields.io/badge/Service_Mesh-Istio-466BB0?style=flat&logo=istio&logoColor=white)](https://istio.io/)
[![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Dashboards-Grafana-F46800?style=flat&logo=grafana&logoColor=white)](https://grafana.com/)
[![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?style=flat&logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)

---

## 📌 What This Project Actually Is

This is **not** a "kubectl apply and call it done" project.

Stan's Robot Shop was deployed on a **multi-node AWS EKS cluster** and deliberately pushed beyond a standard deployment — with real traffic, real autoscaling, real failures, and real debugging. The goal was to understand how a distributed system **behaves under load**, where it **breaks**, and how to **fix it**.

The focus throughout: **system behavior, not just configuration.**

---

## ⚡ Key Results (What Recruiters Care About)

| Metric | Result |
|---|---|
| 🚀 Peak throughput | **~4,850 requests/sec** |
| ✅ Failure rate at 1000 concurrent users | **~0%** |
| ⚡ p95 latency | **~195 ms** |
| 🔍 Bottleneck identified | **Catalogue service at >170% CPU** |
| 🔧 Critical bug fixed | **Istio routing misconfiguration blocking traffic distribution** |
| 📈 HPA validated | **Live autoscaling under sustained load** |

---

## 🏗️ Architecture Overview

```
Users
  │
  ▼
AWS Elastic Load Balancer
  │
  ▼
Istio Ingress Gateway
  │
  ├──► Web (NodeJS Frontend)
  ├──► Catalogue ──► MongoDB
  ├──► Cart ──────► Redis
  ├──► User ──────► MongoDB + Redis
  ├──► Shipping ──► MySQL
  ├──► Ratings ───► MySQL
  ├──► Payment ───► RabbitMQ
  └──► Dispatch ──► RabbitMQ
         │
         ▼
  Prometheus ──► Grafana Dashboards
```

**8-node cluster topology:**
- **5 nodes** → stateless application workloads
- **3 nodes** → dedicated database workloads (isolated with taints)

---

## 🧰 Tech Stack

### Application Layer (Polyglot Microservices)

| Service | Language | Database |
|---|---|---|
| Web | NodeJS + AngularJS | — |
| Catalogue | NodeJS (Express) | MongoDB |
| Cart | — | Redis |
| User | — | MongoDB + Redis |
| Shipping | Java (Spring Boot) | MySQL |
| Ratings | PHP (Apache) | MySQL |
| Payment | Python (Flask) | RabbitMQ |
| Dispatch | Golang | RabbitMQ |

### Infrastructure Layer

| Component | Tool |
|---|---|
| Container Orchestration | AWS EKS (Kubernetes) |
| Service Mesh | Istio |
| Package Management | Helm + Kustomize |
| GitOps | ArgoCD |
| Monitoring | Prometheus + Grafana |
| Load Testing | k6 |
| Messaging | RabbitMQ |

---

## ⚙️ Infrastructure Design

### Multi-Node EKS Cluster

The cluster separates stateful and stateless workloads — a pattern that matters in production:

**Application nodes (×2)** handle all microservice pods. Spread using pod anti-affinity to avoid co-location of critical replicas.

**Database nodes (×1)** are isolated with taints and tolerations. Only database pods can schedule here, preventing compute workloads from starving DB I/O.

```yaml
# Example: DB node taint
taints:
  - key: "workload"
    value: "database"
    effect: "NoSchedule"

# DB pod toleration
tolerations:
  - key: "workload"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
```

**Why this matters:** Without node isolation, a CPU-hungry microservice pod can be co-located with MongoDB, and suddenly your DB performance collapses under load. Many projects skip this and then misdiagnose the root cause.

### Scheduling Constraints

Three layers of scheduling control are applied:

- **Node affinity** — forces pods to specific node types
- **Pod affinity** — co-locates related services for lower latency
- **Pod anti-affinity** — spreads replicas across nodes for availability

---

## 🚀 Deployment Methods

Kustomize is implemented so you can compare real-world approaches:

### Kustomize (Overlay-Based Deployment)

Best for declarative environment variations without templating complexity.

```bash
kubectl apply -k kustomize/overlays/production/
```


---

## 🔁 GitOps with ArgoCD

The cluster is managed via ArgoCD — every change goes through Git, not `kubectl apply` on a laptop.

**What ArgoCD manages here:**
- Application grouping by service
- Automated sync on Git push
- Health status and rollout visibility
- Drift detection between desired and live state

### ArgoCD Screenshots

<img width="1406" height="444" alt="Screenshot 2026-04-13 182618" src="https://github.com/user-attachments/assets/ceb64a4d-d6ce-4422-a71d-2210eccd1ee3" />


---

## 🔀 Istio Service Mesh & The Bug I Had to Fix

### The Problem

After deploying Istio, all inbound traffic was being routed **only to the Web service**. Under load testing, only Web pods were scaling — everything else sat idle. The performance numbers looked acceptable, but they were measuring the **wrong thing**.

**Root cause:** The Istio VirtualService was missing path-based routing rules. All traffic defaulted to the frontend.

### The Fix

```yaml
# VirtualService — path-based routing
http:
  - match:
      - uri:
          prefix: /api/catalogue
    route:
      - destination:
          host: catalogue
  - match:
      - uri:
          prefix: /api/user
    route:
      - destination:
          host: user
  - route:
      - destination:
          host: web
```

### Result After Fix

| Before | After |
|---|---|
| Only Web scaled | Multiple services scaled under HPA |
| Catalogue idle | Catalogue hit >170% CPU — real bottleneck exposed |
| Performance numbers misleading | Accurate service-level load distribution |

**Key lesson:** Routing configuration directly affects what your autoscaler sees. If traffic never reaches a service, its HPA will never trigger — and you'll miss the actual bottleneck entirely.

---

## 📊 Load Testing with k6

Realistic user behavior was simulated — not just hitting one endpoint:

```javascript
// k6 script: simulated user journey
export default function () {
  http.get(`${BASE_URL}/`);                    // Homepage
  http.get(`${BASE_URL}/api/catalogue/`);      // Browse products
  http.get(`${BASE_URL}/api/catalogue/${id}`); // Product detail
  sleep(1);
}
```

**Test configuration:** 1,000 virtual users (VUs), sustained load, ramped over time.

### Results

| Metric | Value |
|---|---|
| Throughput | ~4,850 req/sec |
| p95 latency | ~195 ms |
| p99 latency | ~410 ms |
| Failure rate | ~0% |
| Max spike observed | ~8s (investigated — traced to DB cold start) |

### k6 Screenshots
<img width="978" height="773" alt="Screenshot 2026-04-13 182755" src="https://github.com/user-attachments/assets/fcf63160-069a-4728-bf4a-b5f57b3de278" />


---

## 📈 Autoscaling (HPA + VPA)

### HPA Configuration

CPU-based HPA was configured per service with individual thresholds:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: catalogue
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: catalogue
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

### What Actually Happened Under Load

| Service | Behavior |
|---|---|
| Catalogue | Scaled to max replicas — confirmed CPU bottleneck at >170% |
| Web | Scaled moderately — handled frontend load |
| Cart, User, Payment | Remained near idle — traffic pattern didn't trigger them |

### VPA

Vertical Pod Autoscaling was also deployed alongside HPA to right-size resource requests based on observed usage. Running both is uncommon but powerful — it prevents over-provisioning while HPA handles burst scaling.

> ⚠️ **Note:** HPA + VPA together requires careful tuning. VPA changing resource requests can interfere with HPA's CPU utilization calculation if not configured correctly (VPA set to `UpdateMode: Off` for HPA-managed deployments).
---

## 🔍 Observability Stack

Real-time visibility into every layer of the system:

**Prometheus** scrapes metrics from all pods, the Istio control plane, and node exporters.

**Grafana** dashboards surface:
- Per-service CPU and memory usage
- Request rate and error rate per service
- HPA replica counts over time
- p95/p99 latency per endpoint
- RabbitMQ queue depth

**Istio telemetry** provides:
- Service-to-service traffic maps
- Distributed tracing (via Jaeger integration)
- Latency breakdowns per hop

### Grafana Dashboard Screenshots

> *(Add Grafana screenshots here)*

---

## 💥 Chaos Engineering & Failure Testing

Resilience was tested deliberately — not just hoped for.

### Pod Failure

```bash
# Delete a running catalogue pod
kubectl delete pod -l app=catalogue -n robot-shop
```

**Observed:** Kubernetes self-healing — new pod scheduled and running within ~15 seconds. No user-visible errors due to multiple replicas.

### CPU Stress Injection

```bash
# Inject CPU stress inside a running pod
kubectl exec -it <pod> -- stress --cpu 4 --timeout 60s
```

**Observed:** HPA detected CPU spike within ~30 seconds and began scaling. New replicas became ready and absorbed load.

### Database Failure Simulation

Simulated MongoDB downtime by scaling the MongoDB deployment to 0 replicas.

**Observed:** Catalogue service began returning 5xx errors. Other services (Cart on Redis, Shipping on MySQL) continued operating normally — confirming proper service isolation.

---

## 🧠 What I Actually Learned

These aren't "best practices" from a blog post. These came from breaking things and debugging them:

**1. Routing config determines what your autoscaler sees.**
HPA can't scale a service that never receives traffic. Getting Istio routing right was the prerequisite for everything else working.

**2. CPU-based HPA is not always enough.**
Under bursty I/O workloads, CPU stays low while latency spikes. Custom metrics (RPS, queue depth, latency) are needed for accurate scaling signals.

**3. The 8-second latency spike was a DB cold start, not a CPU problem.**
Observability with Grafana + Prometheus was what made this traceable. Without it, this would have looked like a random anomaly.

**4. VPA + HPA together requires deliberate configuration.**
Setting VPA to `UpdateMode: Off` on HPA-managed workloads prevents them from conflicting over resource requests.

**5. Node isolation prevents invisible performance degradation.**
Mixing stateful (DB) and stateless (app) workloads without taints causes noisy-neighbour issues that only show up under load.

---

## 🔮 Planned Improvements

- [ ] Custom metrics HPA using Prometheus adapter (scale on RPS and p95 latency, not just CPU)
- [ ] Full end-to-end user journey simulation in k6 (browse → cart → checkout → payment)
- [ ] Database-level observability (MongoDB exporter, MySQL exporter, Redis exporter)
- [ ] Canary deployments via Istio traffic splitting (10% → 50% → 100%)
- [ ] CI/CD pipeline with GitHub Actions triggering ArgoCD sync
- [ ] Karpenter for intelligent node autoscaling on EKS

---

## 📁 Repository Structure

```
.
├── helm/                    # Helm chart for full deployment
│   ├── templates/           # Kubernetes manifests (templated)
│   └── values.yaml          # Default configuration values
├── kustomize/               # Kustomize-based deployment
│   ├── base/                # Base manifests
│   └── overlays/            # Environment-specific patches
│       ├── dev/
│       └── production/
├── k6/                      # Load testing scripts
│   └── load-test.js
├── monitoring/              # Prometheus + Grafana config
│   ├── prometheus/
│   └── grafana/dashboards/
└── docs/                    # Architecture diagrams, screenshots
```

---

## 🚀 Quick Start

### Prerequisites

- AWS EKS cluster (≥8 nodes recommended)
- `kubectl`, `helm`, `istioctl` installed
- ArgoCD deployed on cluster

### Deploy with Helm

```bash
# 1. Add Istio and apply CRDs
istioctl install --set profile=production -y

# 2. Create namespace with Istio injection
kubectl create namespace robot-shop
kubectl label namespace robot-shop istio-injection=enabled

# 3. Deploy Robot Shop
helm install robot-shop ./helm/ \
  --namespace robot-shop \
  -f helm/values.yaml

# 4. Verify all pods are running
kubectl get pods -n robot-shop

# 5. Get the external load balancer URL
kubectl get svc -n istio-system istio-ingressgateway
```

### Deploy with Kustomize

```bash
kubectl apply -k kustomize/overlays/production/
```

### Run Load Test

```bash
k6 run k6/load-test.js \
  --vus 1000 \
  --duration 5m \
  --env BASE_URL=http://<your-elb-url>
```

---
 <img width="1892" height="502" alt="image" src="https://github.com/user-attachments/assets/5aa50764-4460-495c-98a4-4fcb8f33f715" />
<img width="1892" height="903" alt="image" src="https://github.com/user-attachments/assets/57907ff9-51c2-4c09-9d9b-7211eefbc200" />
<img width="1592" height="776" alt="image" src="https://github.com/user-attachments/assets/0d6627c4-31ad-4335-b1b8-d47780744c00" />
<img width="1891" height="898" alt="image" src="https://github.com/user-attachments/assets/582a508d-02de-44d7-89f7-a63653d0ca4d" />

---

## 🎯 Summary

This project demonstrates practical, hands-on experience with:

| Area | What Was Done |
|---|---|
| **Kubernetes scheduling** | Node affinity, taints, tolerations, pod anti-affinity on 8-node EKS |
| **Service mesh** | Istio traffic routing, debugged and fixed a real misconfiguration |
| **Autoscaling** | HPA + VPA deployed and validated under real load |
| **Performance testing** | k6 at 1000 VUs, ~4850 RPS, p95 < 200ms |
| **Observability** | Prometheus + Grafana, service-level metrics, latency tracing |
| **Chaos engineering** | Pod failure, CPU stress injection, database downtime simulation |
| **GitOps** | ArgoCD managing full application lifecycle |
| **Deployment tooling** | Helm + Kustomize, both approaches implemented and compared |

The difference between this and a tutorial project: **things were broken, debugged, and fixed** — and that's documented here. 

