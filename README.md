# Introduction

A simple Docker container that will uses `nmap` to scan a set of servers on a
regular interval and sends an email when `ndiff` detects a change.

# Configuration

Store configuration files in an environment file, such as `/etc/sysconfig/docker-nmap-scans`, Example:

```
# TARGETS is a space separated list of targets passed to nmap to scan and
# supports all targets that nmap supports. Required.
TARGETS=host.example.com 192.0.2.1 198.51.100.0/24

# MAILTO is the email address ndiff results are sent to. Required.
MAILTO=user@example.com

# INTERVAL is the runtime in seconds between scans. Required.
INTERVAL=86400

# OPTIONS is the arguments passed to nmap. Optional, defaults to '-Pn'.
# OPTIONS=-Pn -T5 -p 22,80 -oA

# TZ is the timezone. Optional.
# TZ=Australia/Adelaide

# BASE_DIR is used by systemd service file and represents path this repo without
# trailing spaces. Required for sample systemd service file, otherwise ignored.
# BASE_DIR=/home/user/dockers/nmap-scans
```

# Running

```
docker run -d --restart=on-failure -v /base_dir/scripts:/scripts -v /base_dir/results:/results --env-file=/etc/sysconfig/docker-nmap-scans --name=nmap-scans nmap-scans
docker logs nmap-scans
```

# systemd

An example systemd service file and installation instructions. Alternative use the `--restart` [Docker argument](https://docs.docker.com/reference/run/#restart-policies-restart).

```
cp systemd-docker-nmap-scans.service /etc/systemd/system/docker-nmap-scans.service
systemctl enable docker-nmap-scans
systemctl start docker-nmap-scans
systemctl status docker-nmap-scans
```
