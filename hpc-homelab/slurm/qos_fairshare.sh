#!/usr/bin/env bash
# =========================================================
# qos_fairshare.sh — Slurm accounts, QoS, and fairshare
# Run after slurmdbd is healthy. Safe to re-run (idempotent).
# =========================================================

set -euo pipefail

SACCTMGR="sacctmgr -i"

echo "==> Creating cluster record"
$SACCTMGR add cluster homelab || true

echo "==> Creating top-level accounts"
$SACCTMGR add account research   Description="Research groups"    Organization=university || true
$SACCTMGR add account admin      Description="Sysadmin testing"   Organization=university || true
$SACCTMGR add account guest      Description="Guest/limited users" Organization=university || true

echo "==> Creating users under accounts"
$SACCTMGR add user researcher01 Account=research DefaultAccount=research || true
$SACCTMGR add user researcher02 Account=research DefaultAccount=research || true
$SACCTMGR add user sysadmin     Account=admin    DefaultAccount=admin    || true
$SACCTMGR add user guestuser    Account=guest    DefaultAccount=guest    || true

echo "==> Defining QoS tiers"
# high: priority jobs, preempts normal/debug
$SACCTMGR add qos high   Priority=1000   Preempt=normal,debug   GrpTRES=cpu=6   MaxTRESPerUser=cpu=4   MaxWallDurationPerJob=48:00:00 || true

# normal: standard research workloads
$SACCTMGR add qos normal   Priority=500   Preempt=debug   GrpTRES=cpu=4   MaxTRESPerUser=cpu=2   MaxWallDurationPerJob=24:00:00 || true

# debug: short test jobs, lowest priority, can be preempted
$SACCTMGR add qos debug   Priority=100   GrpTRES=cpu=2   MaxTRESPerUser=cpu=1   MaxWallDurationPerJob=00:30:00 || true

echo "==> Assigning QoS to accounts"
$SACCTMGR modify account research withassoc set QOS=normal,high   || true
$SACCTMGR modify account admin    withassoc set QOS=high,normal,debug || true
$SACCTMGR modify account guest    withassoc set QOS=debug          || true

echo "==> Setting fairshare weights"
$SACCTMGR modify account research withassoc set Fairshare=100 || true
$SACCTMGR modify account admin    withassoc set Fairshare=50  || true
$SACCTMGR modify account guest    withassoc set Fairshare=10  || true

echo "==> Done. Verify with: sacctmgr show assoc format=account,user,qos,fairshare"
sacctmgr show assoc format=account,user,qos,fairshare
