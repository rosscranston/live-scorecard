# Ubuntu First Clone — Before the Repository Exists Locally

Use this page when the private repository already exists on GitHub but the Ubuntu/Hermes computer has not cloned it yet.

## 1. Install minimum tools

```bash
sudo apt update
sudo apt install -y git openssh-client curl ca-certificates
```

## 2. Generate an Ubuntu-only deploy key

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "ai-os-ubuntu-hermes" -N "" -f ~/.ssh/ai-os-ubuntu-hermes
cat ~/.ssh/ai-os-ubuntu-hermes.pub
```

Copy only the displayed `.pub` line to the Mac. On the Mac:

```bash
gh repo deploy-key add /tmp/ubuntu-ai-os.pub   --repo OWNER/ai-operating-system   --title ai-os-ubuntu-hermes   --allow-write
```

## 3. Configure the SSH alias on Ubuntu

```bash
cat >> ~/.ssh/config <<'EOF'
Host github-ai-os
  HostName github.com
  User git
  IdentityFile ~/.ssh/ai-os-ubuntu-hermes
  IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
# GitHub's published Ed25519 host key and fingerprint:
# SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU
GITHUB_HOST_KEY='github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'
grep -Fqx "$GITHUB_HOST_KEY" ~/.ssh/known_hosts 2>/dev/null || printf '%s\n' "$GITHUB_HOST_KEY" >> ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts
```

## 4. Clone

```bash
mkdir -p ~/AI
cd ~/AI
git clone git@github-ai-os:OWNER/ai-operating-system.git
cd ai-operating-system
./scripts/guided-install-ubuntu.sh
```
