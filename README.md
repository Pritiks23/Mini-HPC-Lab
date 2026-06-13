# Mini-HPC-Lab


A fully reproducible, IaC-managed HPC cluster running in Docker Compose.
Demonstrates production-grade Slurm administration, Ansible configuration
management, Open OnDemand, Lmod environment modules, Prometheus monitoring,
and Linux security hardening — all runnable in a single GitHub Codespace.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  hpc-homelab cluster                │
│                                                     │
│  ┌──────────────┐    ┌──────────────┐               │
│  │  slurmctld   │    │  slurmdbd    │               │
│  │  (scheduler) │◄──►│  (accounting)│               │
│  └──────┬───────┘    └──────┬───────┘               │
│         │                  │                        │
│         ▼                  ▼                        │
│      ┌──────────────────────────┐                   │
│      │         MariaDB          │                   │
│      └──────────────────────────┘                   │
│                                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │  node01  │ │  node02  │ │  node03  │            │
│  │ (slurmd) │ │ (slurmd) │ │ (slurmd) │            │
│  └──────────┘ └──────────┘ └──────────┘            │
│                                                     │
│  ┌──────────────┐    ┌──────────────┐               │
│  │  Prometheus  │    │   Grafana    │               │
│  │  :9090       │◄──►│   :3000      │               │
│  └──────────────┘    └──────────────┘               │
└─────────────────────────────────────────────────────┘
```

## Skills demonstrated

| Area | Tools |
|---|---|
| HPC Scheduler | Slurm 23.x — partitions, QoS, fairshare, preemption |
| Configuration Management | Ansible (roles) + Chef (cookbook) |
| Infrastructure as Code | Docker Compose, Ansible, all config in Git |
| Cluster Provisioning | Warewulf-style node image pattern via Docker |
| Environment Modules | Lmod + Lua modulefiles (GCC, OpenMPI) |
| Interactive HPC Portal | Open OnDemand — job composer + Jupyter |
| Monitoring & Alerting | Prometheus + Grafana + Alertmanager |
| Security & Compliance | auditd, SSH hardening, CIS controls, patch mgmt |
| Version Control | Git — feature branches, tagged releases |
| Documentation | Runbooks, capacity planning docs, this README |

## Repo structure

```
hpc-homelab/
├── docker-compose.yml          # Full cluster as Docker services
├── ansible/
│   ├── inventory/hosts.yml     # Node groups (controller, compute, etc.)
│   ├── playbooks/
│   │   ├── site.yml            # Master playbook — runs everything
│   │   ├── slurm.yml           # Slurm install + QoS bootstrap
│   │   ├── lmod.yml            # Lmod + modulefiles
│   │   ├── ood.yml             # Open OnDemand portal
│   │   └── hardening.yml       # CIS hardening, auditd, SSH policy
│   └── roles/                  # Ansible roles (one per component)
├── slurm/
│   ├── slurm.conf              # Partitions, scheduling, preemption config
│   ├── slurmdbd.conf           # Accounting database config
│   └── qos_fairshare.sh        # sacctmgr bootstrap — accounts + QoS tiers
├── lmod/
│   ├── gcc/12.3.0.lua          # GCC compiler modulefile
│   └── openmpi/4.1.lua         # OpenMPI modulefile (depends on GCC)
├── monitoring/
│   ├── prometheus.yml          # Scrape config (node, slurm, cadvisor)
│   └── alerts/cluster.yml      # Alert rules: NodeDown, QueueDepth, WaitTime
├── security/
│   ├── audit.rules             # auditd rules (NIST AU controls)
│   └── sshd_hardening.conf     # SSH drop-in hardening config
├── chef/
│   └── cookbooks/hpc-node/
│       └── recipes/default.rb  # Chef mirror of the Ansible compute role
├── docs/
│   ├── runbook-slurm.md        # Operational runbook — drain, failures, users
│   └── capacity-planning.md    # Metrics, thresholds, growth triggers
└── tests/
    └── submit_test_jobs.sh     # End-to-end job submission + preemption test
```

## Quick start (GitHub Codespace)

```bash
# 1. Clone and enter repo
git clone https://github.com/YOUR_USERNAME/hpc-homelab.git
cd hpc-homelab

# 2. Install dependencies
sudo apt-get update && sudo apt-get install -y ansible python3-pip
pip3 install ansible-lint

# 3. Start the cluster
docker compose up -d

# 4. Wait for Slurm to be healthy (~30s), then verify
docker exec slurmctld sinfo

# 5. Run the full Ansible deployment
ansible-playbook ansible/playbooks/site.yml

# 6. Bootstrap accounts and QoS
docker exec slurmctld bash /tmp/qos_fairshare.sh

# 7. Submit a test job
docker exec slurmctld sbatch --wrap="hostname && sleep 10"

# 8. Open Grafana: http://localhost:3000  (admin / admin)
# 9. Open Prometheus: http://localhost:9090
```

## Key demo commands

```bash
# Show cluster partitions and node states
docker exec slurmctld sinfo -Nl

# Show QoS tiers
docker exec slurmctld sacctmgr show qos format=name,priority,preempt,grptres

# Show fairshare tree
docker exec slurmctld sshare -al

# Submit a preemptible job (low priority)
docker exec slurmctld sbatch --qos=debug --wrap="sleep 120" --job-name=low_priority

# Submit a high-priority job that preempts it
docker exec slurmctld sbatch --qos=high --wrap="sleep 30" --job-name=high_priority

# Watch the queue live
watch -n2 "docker exec slurmctld squeue -a"
```

## Ports

| Service | URL |
|---|---|
| Grafana | http://localhost:3000 (admin/admin) |
| Prometheus | http://localhost:9090 |
| Open OnDemand | http://localhost:8080 |
| Alertmanager | http://localhost:9093 |

## Git workflow

```bash
# Feature development
git checkout -b feature/add-gpu-partition
# ... make changes ...
git add -A && git commit -m "feat: add gpu partition with gres config"
git push origin feature/add-gpu-partition
# Open PR → merge → tag release
git tag -a v1.1.0 -m "Add GPU partition support"
git push origin v1.1.0
```

## License

MIT — free to use as a portfolio project or learning reference.
