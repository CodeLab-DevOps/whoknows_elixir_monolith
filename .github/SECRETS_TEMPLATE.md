# GitHub Secrets Configuration Template

This file documents all required and optional secrets for the CI/CD pipeline.

## How to Add Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add each secret listed below

## Required Secrets for Deployment

### SSH_PRIVATE_KEY
**Description**: Private SSH key for accessing the production server

**How to generate**:
```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/whoknows_deploy_key

# Copy the public key to your server
ssh-copy-id -i ~/.ssh/whoknows_deploy_key.pub your-user@your-server.com

# Display private key (copy this entire output to GitHub Secrets)
cat ~/.ssh/whoknows_deploy_key
```

**Example value**:
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBK...
-----END OPENSSH PRIVATE KEY-----
```

---

### DEPLOY_HOST
**Description**: Production server hostname or IP address

**How to find**:
```bash
# Your server's public IP or domain name
```

**Example value**:
```
123.45.67.89
```
or
```
whoknows.example.com
```

---

### DEPLOY_USER
**Description**: SSH username for server access

**Example value**:
```
deploy
```
or
```
ubuntu
```
or
```
your-username
```

---

### PRODUCTION_URL (Optional)
**Description**: Full URL where your application will be accessible (with domain and SSL)

**When to use**:
- Set this if you have a domain name configured (e.g., `whoknows.example.com`)
- Leave empty for first deployment - the pipeline will test using the server IP instead

**Example value**:
```
https://whoknows.example.com
```
or
```
http://whoknows.example.com
```

**For first deployment**: Leave this empty and the smoke tests will use `http://{DEPLOY_HOST}` instead

---

### PHX_HOST (Optional)
**Description**: Phoenix host setting for URL generation (defaults to DEPLOY_HOST if not set)

**When to use**:
- Set this if you have a domain name
- Leave empty to use the server IP address

**Example value**:
```
whoknows.example.com
```
or
```
codelab-devops.dk
```

---

### SECRET_KEY_BASE
**Description**: Phoenix secret key for session encryption (minimum 64 characters)

**How to generate**:
```bash
# Run this in your Elixir project
mix phx.gen.secret
```

**Example value**:
```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7l8
```

**Important**:
- Must be at least 64 characters
- Keep this secret secure
- Use different values for dev/test/prod

---

## Optional Secrets

### CODECOV_TOKEN
**Description**: Token for uploading test coverage reports to codecov.io

**How to get**:
1. Sign up at https://codecov.io
2. Link your GitHub repository
3. Copy the upload token

**Example value**:
```
a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6
```

---

### GITHUB_TOKEN (Automatic)
**Description**: Automatically provided by GitHub Actions

**Note**: You don't need to add this manually. GitHub provides it automatically for:
- Pushing Docker images to GitHub Container Registry
- Accessing repository metadata

---

## Verification Checklist

Before running the pipeline, verify all required secrets are configured:

### Required (Must have)
- [ ] `SSH_PRIVATE_KEY` - Full private key with BEGIN/END lines
- [ ] `DEPLOY_HOST` - Server IP or hostname
- [ ] `DEPLOY_USER` - SSH username
- [ ] `SECRET_KEY_BASE` - 64+ character secret key (generate with `mix phx.gen.secret`)

### Optional (Configure later)
- [ ] `PRODUCTION_URL` - Full application URL (set after domain is configured)
- [ ] `PHX_HOST` - Domain name for Phoenix (defaults to DEPLOY_HOST)
- [ ] `CODECOV_TOKEN` - If using codecov.io for coverage reports

## Testing Secrets

### Test SSH Access
```bash
# On your local machine, test SSH connection
ssh -i ~/.ssh/whoknows_deploy_key $DEPLOY_USER@$DEPLOY_HOST

# If successful, you should be logged into the server
```

### Test Docker Registry Access
```bash
# Test GitHub Container Registry authentication
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin
```

### Verify Production URL
```bash
# Test if production URL is accessible
curl -I $PRODUCTION_URL
```

## Security Best Practices

1. **Never commit secrets to git**
   - Add `.env` to `.gitignore`
   - Use GitHub Secrets for CI/CD
   - Use server environment variables for production

2. **Rotate secrets regularly**
   - Update SSH keys every 6-12 months
   - Generate new `SECRET_KEY_BASE` when compromised
   - Revoke old keys after rotation

3. **Limit access**
   - Only grant repository access to trusted users
   - Use deploy keys with read-only access when possible
   - Create dedicated deploy user with minimal permissions

4. **Audit regularly**
   - Review GitHub Actions logs
   - Monitor server access logs
   - Track secret usage

## Environment-Specific Secrets

If you have multiple environments (staging, production), create separate environments in GitHub:

1. Go to **Settings** > **Environments**
2. Create environments: `staging`, `production`
3. Add environment-specific secrets

Then modify the workflow to use environment-specific secrets:

```yaml
environment:
  name: production
  url: https://whoknows.example.com
```

## Troubleshooting

### Secret not found error
**Error**: `Secret SSH_PRIVATE_KEY not found`

**Solution**: Verify secret name matches exactly (case-sensitive)

### Invalid secret format
**Error**: SSH key format not recognized

**Solution**:
- Include the entire key with `-----BEGIN OPENSSH PRIVATE KEY-----` header
- Don't add quotes around the key
- Ensure no extra whitespace or line breaks

### Permission denied
**Error**: `Permission denied (publickey)`

**Solution**:
- Verify public key is in `~/.ssh/authorized_keys` on server
- Check private key matches public key
- Ensure correct username in `DEPLOY_USER`

## Example: Complete Server Setup

```bash
# 1. On your local machine, generate SSH key
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/whoknows_deploy

# 2. Copy public key to server
ssh-copy-id -i ~/.ssh/whoknows_deploy.pub ubuntu@123.45.67.89

# 3. Test connection
ssh -i ~/.ssh/whoknows_deploy ubuntu@123.45.67.89

# 4. Add to GitHub Secrets:
# SSH_PRIVATE_KEY = (content of ~/.ssh/whoknows_deploy)
# DEPLOY_HOST = 123.45.67.89
# DEPLOY_USER = ubuntu
# PRODUCTION_URL = https://whoknows.example.com
# SECRET_KEY_BASE = (output of: mix phx.gen.secret)
```

## Need Help?

- Review [DEPLOYMENT.md](DEPLOYMENT.md) for full deployment guide
- Check GitHub Actions logs for specific error messages
- Verify server prerequisites are met
