# HPC cluster capacity planning

"""
Capacity planning for HPC clusters requires tracking three dimensions:
CPU/core utilization, memory pressure, and storage throughput.
This document describes the metrics we collect, the thresholds we act on,
and the process for recommending new hardware.
"""

## Key metrics and collection

| Metric | Source | Alert threshold |
|---|---|---|
| Node CPU utilization | node_exporter | >85% sustained 1h |
| Node memory utilization | node_exporter | >90% |
| Pending job queue depth | slurm-exporter | >20 jobs for 5min |
| Average job wait time | slurm-exporter | >10 min |
| Scratch filesystem usage | node_exporter | >80% |
| Job throughput (jobs/hr) | slurmdbd | <50% of baseline |

## Utilization targets

- **Target CPU utilization**: 70–80% averaged across all nodes.  
  Below 60% suggests over-provisioning; above 85% sustained means users are waiting.
- **Memory**: never exceed 85% to leave headroom for OS and MPI buffers.
- **Queue depth**: healthy clusters have <10 pending jobs in steady state.

## Monthly review process

1. Pull 30-day Grafana report (CPU, memory, queue depth, job wait time).
2. Identify any partition with average wait time >15 min — candidate for more nodes.
3. Identify any node with average utilization <40% — candidate for consolidation or retirement.
4. Compare against allocations: are accounts consuming their fairshare?
5. Produce written summary with recommendations → reviewed by HPC director.

## Growth triggers (recommend new hardware when)

- Average queue wait time >20 min for two consecutive weeks
- Node count in DRAIN/DOWN >10% of total capacity for >1 week
- Any partition at 100% utilization for >4 hours/day consistently

## Prometheus queries for monthly report

```promql
# 30-day average CPU utilization per node
avg_over_time(
  (1 - avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])))[30d:1h]
) * 100

# Peak queue depth last 30 days
max_over_time(slurm_queue_total{state="PENDING"}[30d])

# 95th percentile job wait time
histogram_quantile(0.95, rate(slurm_job_wait_seconds_bucket[30d]))
```
