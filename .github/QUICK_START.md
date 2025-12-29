# CI/CD Quick Start Guide

This is a simplified guide to get your CI/CD pipeline running quickly.

## Prerequisites Checklist

- [ ] You have a server with SSH access
- [ ] Server has Docker and Docker Compose installed
- [ ] You have access to your GitHub repository settings

## Step 1: Configure GitHub Secrets (5 minutes)

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these **4 required secrets**:

### 1. SSH_PRIVATE_KEY
```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-deploy" -f ~/.ssh/github_deploy
ssh-copy-id -i ~/.ssh/github_deploy.pub your-user@your-server-ip

# Copy this to GitHub Secret
cat ~/.ssh/github_deploy
```

### 2. DEPLOY_HOST
```
your-server-ip-address
# Example: 123.45.67.89
```

### 3. DEPLOY_USER
```
your-ssh-username
# Example: ubuntu or deploy
```

### 4. SECRET_KEY_BASE
```bash
# Run this in your Elixir project
mix phx.gen.secret
# Copy the output to GitHub Secret
```

**Optional** (can add later):
- `PRODUCTION_URL` - Your domain URL (e.g., `https://yourdomain.com`)
- `PHX_HOST` - Your domain name (e.g., `yourdomain.com`)

## Step 2: Prepare Your Server (10 minutes)

SSH into your server and run:

```bash
# 1. Install Docker (if not installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 2. Install Docker Compose (if not installed)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3. Log out and back in for docker group to take effect
exit

# 4. SSH back in and create app directory
ssh your-user@your-server-ip

sudo mkdir -p /opt/whoknows_app
sudo chown $USER:$USER /opt/whoknows_app
cd /opt/whoknows_app

# 5. Clone your repository
git clone https://github.com/your-username/whoknows_elixir_monolith.git .

# 6. Create .env file
cat > .env << EOF
SECRET_KEY_BASE=$(mix phx.gen.secret)
PHX_HOST=your-server-ip
PORT=4000
DATABASE_PATH=/app/priv/repo/prod.db
MIX_ENV=prod
EOF

# 7. Configure firewall (if using ufw)
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 22/tcp    # SSH
sudo ufw enable
```

## Step 3: Verify Repository Settings (1 minute)

The `docker-compose.prod.yml` file is already configured for your organization repository:

```yaml
services:
  app:
    build: null
    image: ${IMAGE_TAG:-ghcr.io/codelab-devops/whoknows_elixir_monolith:latest}
```

✅ No changes needed - the workflow automatically uses the correct organization path via `${{ github.repository }}`

## Step 4: Configure Package Access for Organization (2 minutes)

Since your repository is in the **CodeLab-DevOps** organization, you need to configure package permissions:

**Option A: Make package public (easiest for initial setup)**
1. After first successful build, go to your organization: `https://github.com/orgs/CodeLab-DevOps/packages`
2. Find the package `whoknows_elixir_monolith`
3. Click on it → **Package settings**
4. Scroll to **Danger Zone** → **Change visibility** → **Public**

**Option B: Use Organization Secret with Personal Access Token (recommended for production)**
1. Create a Personal Access Token (PAT):
   - Go to your GitHub profile → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate new token with `read:packages` scope
2. Add as an organization secret:
   - Go to `https://github.com/orgs/CodeLab-DevOps/settings/secrets/actions`
   - New organization secret: `GHCR_TOKEN`
   - Paste the PAT
3. Update the workflow to use this token (optional, current setup works for public packages)

**Note**: The workflow uses `GITHUB_TOKEN` which works automatically for pushing images. For pulling, either make the package public or use a PAT.

## Step 5: Trigger Deployment

### First Test (without deployment)
Push to a feature branch to test CI and CD1:

```bash
git checkout -b test-pipeline
git push origin test-pipeline
```

Check GitHub Actions tab to see the pipeline run.

### Deploy to Production
When ready, merge to `master`:

```bash
git checkout master
git pull origin master
git push origin master
```

This will trigger the full CI → CD1 → CD2 pipeline and deploy to your server!

## Step 6: Monitor Deployment

1. **Watch GitHub Actions**: Go to your repo → **Actions** tab → Click on the running workflow
2. **Watch Server Logs**: SSH into server and run:
   ```bash
   cd /opt/whoknows_app
   docker-compose logs -f app
   ```

## Step 7: Verify Deployment

After deployment completes, verify:

```bash
# On your server
cd /opt/whoknows_app
docker-compose ps  # All services should be "Up"

# Test locally
curl http://localhost:4000/

# From your computer
curl http://your-server-ip/
```

## Access Your Application

- **Application**: `http://your-server-ip`
- **Grafana**: `http://your-server-ip:3000` (admin/admin)
- **Prometheus**: `http://your-server-ip:9090`

## Troubleshooting

### Pipeline fails at "Build Docker Image"
- Check that you're not hitting GitHub Actions limits
- Verify your Dockerfile syntax
- Check GitHub Actions logs for specific error

### Pipeline fails at "Deploy to Production Server"
- Verify SSH_PRIVATE_KEY is correct (including BEGIN/END lines)
- Test SSH manually: `ssh -i ~/.ssh/github_deploy user@server-ip`
- Check that server has `/opt/whoknows_app` directory

### Deployment succeeds but app doesn't work
```bash
# SSH into server
ssh your-user@your-server-ip
cd /opt/whoknows_app

# Check container status
docker-compose ps

# Check logs
docker-compose logs app

# Restart if needed
docker-compose restart app
```

### Can't pull Docker image from GHCR
- Make the package public (see Step 4 above)
- Or configure PAT with `read:packages` scope

## Next Steps

After successful deployment:

1. **Configure SSL** (if using a domain):
   ```bash
   # On server
   cd /opt/whoknows_app
   docker-compose run --rm certbot certonly --webroot \
     --webroot-path=/var/www/certbot \
     -d yourdomain.com \
     -d www.yourdomain.com

   # Restart nginx
   docker-compose restart nginx
   ```

2. **Set PRODUCTION_URL secret** (after domain is configured)
   - Add `PRODUCTION_URL=https://yourdomain.com` to GitHub Secrets

3. **Set up monitoring alerts** in Grafana

4. **Configure database backups**:
   ```bash
   # Create backup script
   sudo crontab -e
   # Add: 0 2 * * * cd /opt/whoknows_app && docker-compose exec -T app sh -c 'cp /app/priv/repo/prod.db /app/priv/repo/prod.db.backup-$(date +\%Y\%m\%d)'
   ```

## Pipeline Overview

```
┌─────────────────────────────────────────────┐
│ CI: Continuous Integration                  │
│ ✓ Lint & Format Check                       │
│ ✓ Unit Tests                                 │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│ CD1: Build & Test in Containers             │
│ ✓ Build Docker Image → GHCR                 │
│ ✓ Integration Tests                          │
│ ✓ E2E Tests (Playwright)                     │
└─────────────────┬───────────────────────────┘
                  │
                  ▼ (only on master)
┌─────────────────────────────────────────────┐
│ CD2: Deploy to Production                   │
│ ✓ SSH to server                              │
│ ✓ Pull image from GHCR                      │
│ ✓ Start all services (app, nginx, etc.)     │
│ ✓ Run smoke tests                            │
│ ✓ Automatic rollback on failure              │
└─────────────────────────────────────────────┘
```

## Full Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [SECRETS_TEMPLATE.md](SECRETS_TEMPLATE.md) - Detailed secrets documentation
- [ci-cd.yaml](workflows/ci-cd.yaml) - Pipeline configuration

## Getting Help

If you encounter issues:
1. Check the GitHub Actions logs
2. Review the troubleshooting section above
3. Check server logs: `docker-compose logs`
4. Verify all secrets are set correctly
