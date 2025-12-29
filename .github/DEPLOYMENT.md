# Deployment Guide

This document explains how to set up and use the CI/CD pipeline for the WhoKnows Elixir Monolith project.

## Pipeline Overview

The pipeline consists of three main stages:

### 1. **CI (Continuous Integration)**
- **Lint Job**: Code formatting, compilation warnings, unused dependencies
- **Unit Test Job**: Run ExUnit tests with coverage reporting

### 2. **CD1 (Build & Test)**
- **Docker Build**: Build and push image to GitHub Container Registry
- **Integration Tests**: Test against the running Docker container
- **E2E Tests**: Run Playwright tests against the containerized application

### 3. **CD2 (Deploy)**
- **Deploy to Server**: SSH deployment using Docker Compose
- **Smoke Tests**: Verify deployment health and service availability
- **Automatic Rollback**: Rollback on deployment failure

## Required GitHub Secrets

Since this is an **organization repository** (CodeLab-DevOps), configure secrets at the organization level for easier management:

**Organization Secrets** (recommended):
- Go to `https://github.com/orgs/CodeLab-DevOps/settings/secrets/actions`
- Add secrets here to share across all repositories

**Repository Secrets** (alternative):
- Go to your repository → `Settings > Secrets and variables > Actions`
- Add secrets specific to this repository only

Configure these required secrets:

### Required Secrets

| Secret Name | Description | Required? | Example |
|-------------|-------------|-----------|---------|
| `SSH_PRIVATE_KEY` | Private SSH key for server access | ✅ Required | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `DEPLOY_HOST` | Production server hostname/IP | ✅ Required | `123.45.67.89` or `your-server.com` |
| `DEPLOY_USER` | SSH username for deployment | ✅ Required | `deploy` or `ubuntu` |
| `SECRET_KEY_BASE` | Phoenix secret key (64+ chars) | ✅ Required | Generate with `mix phx.gen.secret` |
| `PRODUCTION_URL` | Production application URL | ⚪ Optional | `https://whoknows.example.com` |
| `PHX_HOST` | Phoenix host for URL generation | ⚪ Optional | `whoknows.example.com` (defaults to DEPLOY_HOST) |

### Optional Secrets

| Secret Name | Description |
|-------------|-------------|
| `CODECOV_TOKEN` | Token for codecov.io coverage reports |

**Note about PRODUCTION_URL:**
- Leave empty for first deployment - the pipeline will test using `http://{DEPLOY_HOST}` instead
- Set after you configure your domain and SSL certificates
- The deployment will succeed without this, but won't test nginx endpoint

## Server Setup Prerequisites

### 1. Prepare Your Server

SSH into your production server and set up the application directory:

```bash
# Create application directory
sudo mkdir -p /opt/whoknows_app
sudo chown $USER:$USER /opt/whoknows_app
cd /opt/whoknows_app

# Clone the repository
git clone https://github.com/your-username/whoknows_elixir_monolith.git .

# Create .env file for production
cp .env.example .env
```

### 2. Configure Environment Variables

Edit `/opt/whoknows_app/.env`:

```bash
# Application
SECRET_KEY_BASE=your_secret_key_from_mix_phx_gen_secret
PHX_HOST=your-domain.com
PORT=4000

# Database
DATABASE_PATH=/app/data/prod.db

# SSL (if using Let's Encrypt)
CERTBOT_EMAIL=your-email@example.com
DOMAIN_NAME=your-domain.com
```

### 3. Install Docker & Docker Compose

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Log out and back in for group changes to take effect
```

### 4. Set Up SSH Access

On your **local machine**, generate an SSH key for deployment:

```bash
# Generate SSH key (don't set a passphrase for CI/CD)
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/whoknows_deploy_key

# Copy public key to server
ssh-copy-id -i ~/.ssh/whoknows_deploy_key.pub your-user@your-server.com

# Test the connection
ssh -i ~/.ssh/whoknows_deploy_key your-user@your-server.com
```

Add the **private key** content to GitHub Secrets as `SSH_PRIVATE_KEY`:

```bash
cat ~/.ssh/whoknows_deploy_key
# Copy the entire output (including BEGIN and END lines)
```

### 5. Using docker-compose.prod.yml Override

The project includes a [docker-compose.prod.yml](../docker-compose.prod.yml) file that overrides the build directive to use pre-built images from GitHub Container Registry.

**How it works:**
- `docker-compose.yml` - Base configuration (uses `build` for local development)
- `docker-compose.prod.yml` - Production override (uses pre-built image from GHCR)

**Deployment uses both files:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

This approach allows:
- Local development: `docker-compose up` (builds locally)
- Production deployment: Uses pre-built image from CI/CD
- No modification needed to the main docker-compose.yml

## Triggering the Pipeline

### Automatic Triggers

- **Push to `master`**: Runs full CI → CD1 → CD2 (deploys to production)
- **Push to `develop` or `docker-AC`**: Runs CI → CD1 only (no deployment)
- **Pull Request**: Runs CI → CD1 only (no deployment)

### Manual Triggers

You can manually trigger workflows from the GitHub Actions tab.

## Monitoring the Pipeline

### View Pipeline Status

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. Select the workflow run to see details

### Pipeline Stages

```
CI Stage (Parallel)
├── Lint & Format Check
└── Unit Tests

↓ (on success)

CD1 Stage (Sequential)
├── Build Docker Image
├── Integration Tests (uses built image)
└── E2E Tests (uses built image)

↓ (on success, master branch only)

CD2 Stage
├── Deploy to Production Server
├── Smoke Tests
└── Rollback (if smoke tests fail)
```

## Deployment Workflow Details

### What Happens During Deployment

1. **Code Checkout**: Latest code from `master` branch
2. **Docker Login**: Authenticate with GitHub Container Registry
3. **SSH Setup**: Configure SSH access to production server
4. **Remote Deployment**:
   - Pull latest code on server
   - Pull latest Docker image from GHCR
   - Stop old containers
   - Start new containers with `docker-compose up -d`
   - Clean up old images
5. **Smoke Tests**:
   - HTTP health check on production URL
   - Verify all Docker services are running
   - Check critical endpoints
6. **Rollback (if tests fail)**:
   - Revert to previous git commit
   - Restart old containers

## Alternative Deployment: GitHub Container Registry Pull

If you prefer to pull images from GHCR instead of rebuilding on the server, the current workflow already does this! The deployment step:

1. Logs into GHCR on the server
2. Pulls the pre-built image
3. Updates docker-compose to use the new image
4. Restarts services

This is **faster** and **more reliable** than rebuilding on the server.

## Troubleshooting

### Deployment Fails at SSH Step

**Issue**: `Permission denied (publickey)`

**Solution**:
- Verify `SSH_PRIVATE_KEY` secret contains the full private key
- Ensure the public key is in `~/.ssh/authorized_keys` on the server
- Check file permissions: `chmod 600 ~/.ssh/authorized_keys`

### Docker Image Pull Fails

**Issue**: `Error response from daemon: unauthorized`

**Solution**:
- Make your GitHub repository public, or
- Create a Personal Access Token (PAT) with `read:packages` scope
- Add PAT as a secret and use it instead of `GITHUB_TOKEN`

### Smoke Tests Fail

**Issue**: Application doesn't respond after deployment

**Solution**:
- SSH into the server: `ssh user@your-server.com`
- Check container logs: `cd /opt/whoknows_app && docker-compose logs`
- Verify environment variables in `.env`
- Check if database volume is properly mounted

### E2E Tests Fail in CI

**Issue**: Playwright tests timeout or fail

**Solution**:
- Increase timeout in [playwright.config.ts](../playwright.config.ts)
- Check if the Docker container is healthy before running tests
- Review Playwright report artifact in GitHub Actions

## Health Check Endpoint

Consider adding a dedicated health check endpoint to your Phoenix app:

```elixir
# lib/whoknows_elixir_monolith_web/router.ex
scope "/", WhoknowsElixirMonolithWeb do
  pipe_through :browser

  get "/health", HealthController, :index
end

# lib/whoknows_elixir_monolith_web/controllers/health_controller.ex
defmodule WhoknowsElixirMonolithWeb.HealthController do
  use WhoknowsElixirMonolithWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", timestamp: DateTime.utc_now()})
  end
end
```

## Production Checklist

Before deploying to production:

- [ ] Set `SECRET_KEY_BASE` (generate with `mix phx.gen.secret`)
- [ ] Configure `PHX_HOST` to your domain
- [ ] Set up SSL certificates (Let's Encrypt via Certbot)
- [ ] Configure firewall (allow ports 80, 443, 22)
- [ ] Set up database backups
- [ ] Configure Prometheus/Grafana monitoring
- [ ] Test SSH access from GitHub Actions
- [ ] Verify all GitHub Secrets are set
- [ ] Test deployment on staging environment first

## Rollback Manually

If you need to rollback manually:

```bash
ssh user@your-server.com
cd /opt/whoknows_app

# Rollback code
git log --oneline  # Find the commit to rollback to
git reset --hard <commit-hash>

# Restart containers
docker-compose down
docker-compose up -d

# Verify
docker-compose ps
curl -f http://localhost:4000/
```

## Security Best Practices

1. **Never commit secrets**: Use GitHub Secrets for sensitive data
2. **Rotate SSH keys**: Regularly update deployment keys
3. **Use least privilege**: Create a dedicated deploy user with minimal permissions
4. **Enable 2FA**: Protect your GitHub account with two-factor authentication
5. **Audit logs**: Regularly review GitHub Actions logs
6. **Network security**: Use firewall rules to restrict access to your server

## Support

For issues with the pipeline:
1. Check the [GitHub Actions logs](../../actions)
2. Review this documentation
3. Create an issue in the repository
