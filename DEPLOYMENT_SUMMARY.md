# VPS Deployment Summary

## Quick Deployment Options

### Option 1: Automated Setup (Recommended)
```bash
# Make script executable and run
chmod +x deploy-manual.sh
sudo ./deploy-manual.sh
```

### Option 2: Manual Step-by-Step
Follow the detailed guide in `MANUAL_DEPLOYMENT.md`

## Key Configuration Details

### Application Settings
- **Port**: 3001 (configurable in .env)
- **Process Manager**: PM2
- **Database**: PostgreSQL
- **Web Server**: Nginx (reverse proxy)

### File Locations
- **App Directory**: `/var/www/personal-finance-tracker`
- **Logs**: `/var/www/personal-finance-tracker/logs/`
- **Nginx Config**: `/etc/nginx/sites-available/personal-finance-tracker`
- **Environment**: `/var/www/personal-finance-tracker/.env`

### Management Commands
```bash
# Check application status
./manage-app.sh status

# Start/stop/restart
./manage-app.sh start
./manage-app.sh stop  
./manage-app.sh restart

# View logs
./manage-app.sh logs

# Update application
./manage-app.sh update

# Database backup
./manage-app.sh backup

# Fix common issues
./manage-app.sh fix
```

## Before Deployment

1. **Update domain in deployment script**:
   ```bash
   # Edit deploy-manual.sh
   DOMAIN="your-domain.com"
   SUBDOMAIN="finance.your-domain.com"
   ```

2. **Point DNS to your server**:
   - Create A record for your domain/subdomain
   - Point to your VPS IP address

3. **Ensure prerequisites**:
   - Ubuntu 20.04+ VPS
   - Root/sudo access
   - Domain name configured

## After Deployment

1. **Install SSL certificate**:
   ```bash
   sudo certbot --nginx -d finance.your-domain.com
   ```

2. **Configure firewall** (if not done by script):
   ```bash
   sudo ufw allow 22
   sudo ufw allow 80
   sudo ufw allow 443
   sudo ufw allow 3001
   sudo ufw enable
   ```

3. **Set up monitoring**:
   ```bash
   pm2 monitor
   ```

## Integration with Existing Applications

The application is designed to coexist with other web applications:

- **Unique port**: Runs on port 3001
- **Separate database**: Own PostgreSQL database
- **Nginx virtual host**: Dedicated server block
- **PM2 process**: Isolated process management
- **System user**: Dedicated application user

## Security Features

- Environment variables for secrets
- HTTPS redirect (after SSL setup)
- Security headers in Nginx
- Database user with limited privileges
- Firewall configuration
- PM2 process isolation

## Performance Optimizations

- Gzip compression
- Static file caching
- PM2 cluster mode support
- Database connection pooling
- Nginx reverse proxy

## Troubleshooting

Common issues and solutions:

1. **Port conflict**: Check if port 3001 is available
2. **Database connection**: Verify PostgreSQL credentials
3. **Permission issues**: Check file ownership
4. **SSL issues**: Ensure domain points to server
5. **PM2 issues**: Check process status and logs

## Backup Strategy

- **Database**: Automated daily backups
- **Application**: Version control recommended
- **SSL certificates**: Auto-renewal with certbot
- **Logs**: Rotated automatically by PM2

## Support Files

- `deploy-manual.sh` - Automated deployment script
- `manage-app.sh` - Application management script
- `MANUAL_DEPLOYMENT.md` - Detailed deployment guide
- `ecosystem.config.js` - PM2 configuration (created during deployment)
- `.env` - Environment variables (created during deployment)

---

**Note**: Remember to secure your database password and environment variables. The deployment script generates secure passwords automatically.