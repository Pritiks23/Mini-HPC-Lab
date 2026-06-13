# Slurm operations runbook

"""
This runbook covers the most common Slurm operational procedures.
Version-controlled in Git so every change is auditable.
All commands assume you are logged into slurmctld as a user in the wheel group.
"""

## Cluster health check

```bash
sinfo -Nl                        # node state summary
squeue -a --format="%.10i %.9P %.20j %.8u %.8T %.10M %.6D %R"
sacct -alX --starttime=today     # today's completed jobs
```

Expected: all nodes in IDLE or ALLOCATED state. DRAIN or DOWN requires action.

---

## Draining a node for maintenance

```bash
# Drain: no new jobs, running jobs finish naturally
scontrol update NodeName=node02 State=DRAIN Reason="Scheduled maintenance 2024-07-01"

# Confirm drain
sinfo -n node02

# After maintenance, return to service
scontrol update NodeName=node02 State=RESUME

# Verify
sinfo -n node02   # should show IDLE
```

---

## Responding to a node down alert (NodeDown alert fires)

```bash
# 1. Check node state
scontrol show node node02

# 2. Check slurmd on the node
ssh node02 systemctl status slurmd

# 3. Restart slurmd if the daemon crashed
ssh node02 systemctl restart slurmd

# 4. If hardware issue, drain and open a ticket
scontrol update NodeName=node02 State=DOWN Reason="Hardware fault — ticket #1234"

# 5. Mark DRAIN instead of DOWN once confirmed safe to let jobs finish
scontrol update NodeName=node02 State=DRAIN Reason="Pending disk replacement"
```

---

## Cancelling all jobs for a user

```bash
# Preview first
squeue -u researcher01

# Cancel
scancel -u researcher01

# Cancel only pending jobs
scancel -u researcher01 -t PENDING
```

---

## Modifying a running job's time limit

```bash
# Extend job 12345 to 48 hours (must not exceed partition MaxTime)
scontrol update JobId=12345 TimeLimit=48:00:00
```

---

## Fairshare investigation

```bash
# Show effective priority for all pending jobs
sprio -lj

# Show account usage (basis for fairshare)
sshare -al

# Reset fairshare usage for an account (use carefully)
sacctmgr modify account research set RawUsage=0
```

---

## Adding a new user

```bash
# 1. Create Linux account
useradd -m -G hpcusers newresearcher

# 2. Add SSH public key
mkdir -p /home/newresearcher/.ssh
echo "ssh-ed25519 AAAA... user@host" >> /home/newresearcher/.ssh/authorized_keys
chmod 700 /home/newresearcher/.ssh
chmod 600 /home/newresearcher/.ssh/authorized_keys
chown -R newresearcher:newresearcher /home/newresearcher/.ssh

# 3. Add Slurm account association
sacctmgr add user newresearcher Account=research DefaultAccount=research

# 4. Verify
sacctmgr show user newresearcher withassoc
```
