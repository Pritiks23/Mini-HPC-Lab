# Mini-HPC-Lab Showcase Evidence

This document organizes live evidence that key platform services are reachable and operating.

## Environment snapshot

- Repository: `Pritiks23/Mini-HPC-Lab`
- Path: `/home/runner/work/Mini-HPC-Lab/Mini-HPC-Lab/Pritiks23/Mini-HPC-Lab`
- Capture date (UTC): 2026-06-13

## Service validation summary

| Check | Result | Evidence |
|---|---|---|
| Docker services running | ✅ Pass | `docker ps -a` output below |
| Prometheus health endpoint | ✅ Pass | `Prometheus Server is Healthy.` |
| Grafana login endpoint | ✅ Pass | HTTP `200 OK` headers |
| Prometheus UI screenshot | ✅ Pass | User-provided screenshot link |
| Grafana UI screenshot | ✅ Pass | User-provided screenshot link |

## Command output evidence

### 1) Container runtime status

```text
NAMES                      IMAGE                     STATUS         PORTS
hpc-homelab-grafana-1      grafana/grafana:10.3.3    Up 9 seconds   0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp
hpc-homelab-prometheus-1   prom/prometheus:v2.51.0   Up 9 seconds   0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
hpc-homelab-mariadb-1      mariadb:10.11             Up 9 seconds   3306/tcp
```

### 2) Prometheus health check

```text
Prometheus Server is Healthy.
```

### 3) Grafana HTTP reachability

```text
HTTP/1.1 200 OK
Cache-Control: no-store
Content-Type: text/html; charset=UTF-8
X-Content-Type-Options: nosniff
X-Frame-Options: deny
X-Xss-Protection: 1; mode=block
Date: Sat, 13 Jun 2026 19:59:41 GMT
Transfer-Encoding: chunked
```

## Screenshot evidence

### Prometheus UI

![Prometheus UI](https://github.com/user-attachments/assets/38d4e7cb-95a5-434a-a5d6-dc42fa8c0d37)

### Grafana Login UI

![Grafana Login UI](https://github.com/user-attachments/assets/5dff8389-285d-44c7-bed7-d784aa27f889)

## Showcase-ready takeaway

The project demonstrably exposes and runs its monitoring plane (Prometheus + Grafana) with healthy and browser-reachable endpoints, and includes visual proof suitable for PR/demo presentation.
