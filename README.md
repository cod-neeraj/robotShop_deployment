---

# Instana Robot Shop – Kubernetes Deployment (Helm & Kustomize)

## Overview

This repository contains Kubernetes manifests for deploying **Stan’s Robot Shop**, a sample microservices application commonly used to explore container orchestration, distributed architecture patterns, and full-stack observability with tools like Instana.

Rather than treating this as a generic demo, this repository intentionally pushes the architecture toward a more realistic environment—including **multi-node topology**, **affinity rules**, **scaling strategies**, and **health checks**—so you can stress-test monitoring and scheduling behaviors.

---

## What Is Robot Shop?

Stan’s Robot Shop is not a perfectly engineered microservice system—nor does it try to be. It’s a deliberately imperfect sandbox where you can observe:

* **Service-to-service communication**
* **Database interactions**
* **Distributed request flows**
* **Messaging queues**
* **Polyglot service design**
* **Latency, failure, and scaling behavior**

Despite its simplicity, it uses a wide mix of technologies:

| Technology         | Used In                   |
| ------------------ | ------------------------- |
| NodeJS (Express)   | Web frontend / API pieces |
| Java (Spring Boot) | Backend services          |
| Python (Flask)     | Utility microservices     |
| Golang             | Lightweight services      |
| PHP (Apache)       | API components            |
| MongoDB            | NoSQL service backing     |
| Redis              | Cache + session storage   |
| MySQL              | Structured data           |
| RabbitMQ           | Asynchronous messaging    |
| Nginx              | Web serving layer         |
| AngularJS 1.x      | Frontend UI               |

This diversity is intentional—it gives monitoring platforms plenty of telemetry varieties to work with.

---

## Application Architecture

### Microservices Included (8 Total)

* **User**
* **Shipping**
* **Ratings**
* **Payment**
* **Dispatch**
* **Catalogue**
* **Cart**
* **Web**

### Databases (3)

* **MySQL**
* **MongoDB**
* **Redis**

### Messaging System

* **RabbitMQ**

### Service Dependencies

| Service   | Depends On | Database       |
| --------- | ---------- | -------------- |
| Cart      |            | Redis          |
| Catalogue |            | MongoDB        |
| Dispatch  |            | RabbitMQ       |
| Payment   |            | RabbitMQ       |
| Ratings   |            | MySQL          |
| Shipping  |            | MySQL          |
| User      |            | MongoDB, Redis |

(And yes—this dependency layout exposes the classic fragility of tightly coupled microservices. Useful for learning, hazardous in production.)

---

## What This Repository Implements

### 1. **Multi-Node Kubernetes Cluster**

Your setup uses **8 nodes**:

* **5 nodes for application workloads**
* **3 nodes dedicated to databases**

This mimics real-world segregation where:

* Stateful components get stable, taint-protected nodes.
* Application pods remain spread across compute nodes.

### 2. **Pod & Node Scheduling Constraints**

To enforce proper workload placement:

* **Node affinity**
* **Pod affinity / anti-affinity**
* **Taints & tolerations**

This is exactly the right approach for avoiding noisy-neighbor scenarios. Many people ignore these and then wonder why their DB performance collapses.

### 3. **Scaling**

Both scaling strategies are implemented:

* **Horizontal Pod Autoscaling (HPA)**
  Reacts to CPU/memory/metrics load.

* **Vertical Pod Autoscaling (VPA)**
  Adjusts resource requests based on usage.

Using both together is uncommon but powerful—though it can cause resource contention if not tuned.

### 4. **Readiness & Liveness Probes**

Health checks are added to ensure:

* Pods don’t serve traffic before they’re ready.
* Faulty services restart automatically.

This matters especially in Robot Shop because services start at different times and dependencies sometimes lag.

---

## Deployment Methods

This repo offers both approaches so you can compare them:

### **1. Helm-Based Deployment**

* Templated
* Highly configurable
* Better for repeatable production-style deployments

### **2. Kustomize Deployment**

* Patch-oriented customization
* Declarative overlays
* Ideal for environment-based variations

Both outputs drive the same multi-node cluster setup.

---

## ArgoCD Integration

<img width="1377" height="427" alt="image" src="https://github.com/user-attachments/assets/3e1c9eea-1b3d-49fd-8671-ce7e6f783a23" />
<img width="1395" height="441" alt="image" src="https://github.com/user-attachments/assets/091cc461-b8c8-419b-b9a1-fc2e470859aa" />
<img width="941" height="432" alt="image" src="https://github.com/user-attachments/assets/264caed0-2ee4-4489-b3f6-36423e0b6cd1" />
<img width="247" height="573" alt="image" src="https://github.com/user-attachments/assets/807b39de-f18e-4a58-94b5-47ab079b01e3" />
<img width="240" height="562" alt="image" src="https://github.com/user-attachments/assets/cae824b0-88e3-457a-87c2-bf2847b5eeb2" />
<img width="248" height="580" alt="image" src="https://github.com/user-attachments/assets/a6d9d71c-8885-4255-a8ce-7a4ded640ab9" />
<img width="252" height="582" alt="image" src="https://github.com/user-attachments/assets/34f10f43-75cf-44e5-9232-b1af719333de" />








Your ArgoCD view showcases:

* Multi-node clusters
* Application grouping
* Sync strategy
* Health & rollout status

This is extremely useful when demonstrating GitOps flows.

---

## Final Notes

This README is not trying to oversell the project—it explains exactly what’s implemented, why it is structured this way, and how it strengthens observability experiments. If you're using Instana or another APM, this architecture gives you rich traces, queue dynamics, cross-service dependency visualization, and scaling signals.

---


