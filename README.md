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

------

What this project is, in plain English

Imagine a university research department where 50 scientists all need to run heavy computations — climate simulations, protein folding, machine learning training runs. They can't all run these on their laptops, so the university buys a cluster: a group of powerful computers all connected together that scientists can submit work to. Someone has to build that cluster, keep it running, decide who gets resources when, make sure it's secure, and fix it when it breaks. That person is an HPC systems administrator, and this project proves you can do that job.
What I built is a miniature version of exactly that environment, running entirely inside a GitHub Codespace. Instead of 500 physical servers in a data center, I have Docker containers simulating the nodes. But every single piece of software, every config file, every security policy — it's all real production tooling, just running at a smaller scale.

Why each piece exists
Slurm is the traffic controller for the cluster. When a scientist submits a job — "run this simulation using 32 CPUs for 6 hours" — Slurm decides which node gets it, when it starts, and what happens if a more important job comes in. I didn't just install Slurm, I configured the priority system: three tiers (high, normal, debug) where a high-priority job can actually kick a lower one off a node mid-run and take its place. That feature is called preemption, and configuring it correctly is extremely important. 
Ansible is how I made the whole thing reproducible. Instead of manually SSHing into each node and typing commands, I wrote playbooks — essentially recipes — that describe exactly what every machine should look like. Run one command and Ansible configures all three nodes simultaneously. This matters because in a real cluster you might have 300 nodes, and doing anything manually would be both slow and error-prone.

Open OnDemand is the browser-based portal that sits on top of everything. Scientists don't want to learn terminal commands — they want to open a browser, launch a Jupyter notebook, and have it run on the cluster automatically. I set that up. It's the difference between a cluster that only experts can use and one that an entire research department can access.

Lmod solves a specific HPC problem: different scientists need different software versions that can conflict with each other. One team needs Python 3.9, another needs 3.11. One needs GCC 11, another needs GCC 12. Lmod lets them each load exactly the versions they need without stepping on each other. You wrote the actual module files in Lua that make this work.

Prometheus and Grafana are the eyes of the operation. Prometheus quietly collects metrics from every node every 15 seconds — CPU usage, memory, how many jobs are waiting, how long they've been waiting. Grafana turns that into dashboards. You also wrote alert rules, so if a node goes offline or the job queue backs up past 50 jobs, someone gets paged. This is capacity planning: knowing before your users complain that something is wrong.
The security layer — auditd rules, SSH hardening, automated patching — exists because HPC clusters at universities and national labs often run on grants that require compliance with security frameworks like NIST 800-53. Every command run on a node gets logged. Root login over SSH is disabled. Weak cipher suites are turned off. These aren't optional extras, they're requirements in regulated research computing environments.
Git and Ansible together mean the entire cluster state lives in version control. Every config change is a commit. You can see exactly what changed, when, and why. If something breaks you can roll back. This is Infrastructure as Code — the cluster isn't defined by what's running on the machines, it's defined by the files in the repository.

