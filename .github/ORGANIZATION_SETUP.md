# Organization Repository Setup Guide

This guide is specifically for the **CodeLab-DevOps** organization setup.

## Key Differences for Organization Repositories

### 1. Package Registry Path
- **Organization**: `ghcr.io/codelab-devops/whoknows_elixir_monolith:latest`
- **Personal**: `ghcr.io/username/whoknows_elixir_monolith:latest`

✅ Already configured correctly in [docker-compose.prod.yml](../docker-compose.prod.yml)

### 2. GitHub Secrets Location

You have two options for storing secrets:

#### Option A: Organization-Level Secrets (Recommended)
**Benefits:**
- Shared across all repositories in the organization
- Easier to manage for multiple projects
- Consistent credentials across deployments

**How to configure:**
1. Go to `https://github.com/orgs/CodeLab-DevOps/settings/secrets/actions`
2. Click **New organization secret**
3. Select which repositories can access each secret

#### Option B: Repository-Level Secrets
**Benefits:**
- Isolated to this specific repository
- More granular control

**How to configure:**
1. Go to repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**

### 3. Package Visibility & Access

After the first successful Docker build, configure package access:

#### Make Package Public (Easiest)
1. Go to `https://github.com/orgs/CodeLab-DevOps/packages`
2. Click on `whoknows_elixir_monolith`
3. **Package settings** → **Change visibility** → **Public**

This allows your server to pull images without authentication.

#### Keep Package Private (More Secure)
If you want to keep the package private, you need to authenticate:

1. **Create a Personal Access Token (PAT)**:
   ```
   GitHub Profile → Settings → Developer settings → Personal access tokens → Tokens (classic)
   Generate new token with scopes:
   - read:packages
   - write:packages (if needed)
   ```

2. **Add as Organization Secret**:
   - Name: `GHCR_TOKEN`
   - Value: Your PAT token

3. **Update the workflow** to use the PAT for pulling images:

```yaml
# In .github/workflows/ci-cd.yaml, update the deploy step:
- name: Deploy via Docker Compose on server
  env:
    GHCR_TOKEN: ${{ secrets.GHCR_TOKEN }}
  run: |
    ssh -i ~/.ssh/deploy_key $DEPLOY_USER@$DEPLOY_HOST << 'ENDSSH'
      # Log in with the PAT instead of GITHUB_TOKEN
      echo "$GHCR_TOKEN" | docker login ghcr.io -u USERNAME --password-stdin
      # ... rest of deployment
    ENDSSH
```

### 4. Organization Permissions

Ensure the GitHub Actions workflow has the necessary permissions:

1. Go to `https://github.com/orgs/CodeLab-DevOps/settings/actions`
2. Under **Workflow permissions**, ensure:
   - ☑️ Read and write permissions (for pushing Docker images)
   - ☑️ Allow GitHub Actions to create and approve pull requests (optional)

### 5. Team Access

If you have multiple team members deploying:

1. Go to `https://github.com/orgs/CodeLab-DevOps/teams`
2. Create a team (e.g., "DevOps Engineers")
3. Add team members
4. Grant team access to the repository
5. Team members can share organization secrets

## Recommended Setup for CodeLab-DevOps

### Organization Secrets (Shared)
These can be shared across multiple projects:
- `DEPLOY_HOST` - Your production server IP
- `DEPLOY_USER` - SSH username for deployment
- `SSH_PRIVATE_KEY` - Deployment SSH key (if using same server for multiple projects)

### Repository Secrets (Project-Specific)
These are specific to this application:
- `SECRET_KEY_BASE` - Phoenix secret for this app
- `PHX_HOST` - Domain for this app (if different per project)
- `PRODUCTION_URL` - URL for this app (if different per project)

## Package Management Strategy

For the **CodeLab-DevOps** organization, we recommend:

### Development/Testing Packages
- Keep development/staging images **private**
- Use branch-specific tags (e.g., `ghcr.io/codelab-devops/whoknows_elixir_monolith:dev`)

### Production Packages
- Option 1: **Public** (if application code is open-source)
- Option 2: **Private** with PAT authentication (for proprietary code)

### Package Lifecycle
```
Feature Branch → PR → Merge to Main → Production Tag
     ↓              ↓         ↓              ↓
  pr-123        pr-123   sha-abc123      latest
  (private)    (private)  (private)      (public/private)
```

## Monitoring Organization Usage

Track your organization's GitHub Actions usage:

1. Go to `https://github.com/orgs/CodeLab-DevOps/settings/billing`
2. View **Actions & Packages** usage
3. Set up spending limits if needed

**Free tier includes:**
- 2,000 Actions minutes/month (Linux runners)
- 500MB package storage

**Tips to reduce usage:**
- Use caching (already configured in workflow)
- Only run full pipeline on `master` branch
- Use self-hosted runners for unlimited minutes

## Security Best Practices for Organizations

### 1. Require Review for Deployments
Add a production environment with required reviewers:

```yaml
# In .github/workflows/ci-cd.yaml
deploy:
  environment:
    name: production
    url: ${{ secrets.PRODUCTION_URL }}
  # Requires approval before deploying
```

Configure in: Repository → Settings → Environments → production → Required reviewers

### 2. Branch Protection Rules
Protect the `master` branch:

1. Repository → **Settings** → **Branches** → Add rule for `master`
2. Enable:
   - ☑️ Require a pull request before merging
   - ☑️ Require status checks to pass (CI must pass)
   - ☑️ Require branches to be up to date

### 3. Audit Logs
Monitor deployment activity:
- `https://github.com/orgs/CodeLab-DevOps/settings/audit-log`
- Filter by `action:workflow_run` to see deployments

### 4. Dependabot Alerts
Enable security scanning:
1. Repository → **Settings** → **Security & analysis**
2. Enable:
   - ☑️ Dependabot alerts
   - ☑️ Dependabot security updates
   - ☑️ Secret scanning

## Multi-Environment Setup for Organizations

If you want separate staging and production environments:

### 1. Create Environment-Specific Secrets

**Staging Environment:**
- `STAGING_DEPLOY_HOST`
- `STAGING_SECRET_KEY_BASE`
- `STAGING_URL`

**Production Environment:**
- `PRODUCTION_DEPLOY_HOST` (or just `DEPLOY_HOST`)
- `PRODUCTION_SECRET_KEY_BASE` (or just `SECRET_KEY_BASE`)
- `PRODUCTION_URL`

### 2. Update Workflow

```yaml
deploy-staging:
  if: github.ref == 'refs/heads/develop'
  environment:
    name: staging
  # ... deploy to staging server

deploy-production:
  if: github.ref == 'refs/heads/master'
  environment:
    name: production
  # ... deploy to production server
```

## Team Collaboration

### Code Review Process
1. Developer creates feature branch
2. CI runs lint + unit tests automatically
3. Creates PR to `master`
4. Team reviews code
5. CD1 builds Docker image and runs E2E tests
6. Merge to `master` triggers production deployment
7. CD2 deploys to server with smoke tests

### Notification Setup
Get notified of deployments:

1. **Slack Integration**:
   - Add GitHub app to Slack
   - Subscribe to repository: `/github subscribe CodeLab-DevOps/whoknows_elixir_monolith deployments`

2. **Email Notifications**:
   - Watch the repository
   - Configure notification preferences

## Troubleshooting Organization Issues

### "Resource not accessible by integration"
**Cause**: Insufficient workflow permissions

**Fix**:
- Go to organization settings → Actions → Workflow permissions
- Enable "Read and write permissions"

### "Package does not exist or requires authentication"
**Cause**: Package is private and server cannot pull

**Fix**:
- Make package public, OR
- Use PAT for authentication on the server

### "Secret not found"
**Cause**: Secret is at wrong level (org vs repo)

**Fix**:
- Check both organization and repository secrets
- Ensure organization secret is available to this repository

## Next Steps

1. ✅ Configure organization secrets at `https://github.com/orgs/CodeLab-DevOps/settings/secrets/actions`
2. ✅ Set up branch protection for `master`
3. ✅ Configure production environment with required reviewers
4. ✅ Make first deployment
5. ✅ Set up package visibility (public or private with PAT)
6. ⬜ Configure Slack notifications (optional)
7. ⬜ Set up staging environment (optional)

## Resources

- [GitHub Organizations Documentation](https://docs.github.com/en/organizations)
- [GitHub Packages Documentation](https://docs.github.com/en/packages)
- [GitHub Actions for Organizations](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments)
