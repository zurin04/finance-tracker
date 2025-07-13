# Manual VPS Deployment Guide

This guide will help you deploy the Personal Finance Tracker on a VPS that's already running other web applications.

## Prerequisites

- Ubuntu 20.04+ VPS with sudo access
- Domain or subdomain pointed to your server IP
- Basic knowledge of Linux command line

## Quick Start

1. **Upload files to your VPS:**
   ```bash
   # On your local machine
   scp -r . user@your-server-ip:/tmp/finance-tracker/
   
   # On your VPS
   sudo mv /tmp/finance-tracker /var/www/
   ```

2. **Run the deployment script:**
   ```bash
   cd /var/www/finance-tracker
   sudo chmod +x deploy-manual.sh
   sudo ./deploy-manual.sh
   ```

3. **Update the domain configuration:**
   ```bash
   sudo nano /etc/nginx/sites-available/personal-finance-tracker
   # Change the server_name to your domain
   ```

4. **Install SSL certificate:**
   ```bash
   sudo certbot --nginx -d your-domain.com
   ```

## Manual Configuration

### 1. System Requirements

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib

# Install PM2 globally
sudo npm install -g pm2

# Install Nginx (if not already installed)
sudo apt-get install -y nginx
```

### 2. Database Setup

```bash
# Create database and user
sudo -u postgres psql
CREATE DATABASE finance_tracker;
CREATE USER finance_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE finance_tracker TO finance_user;
ALTER USER finance_user CREATEDB;
\q
```

### 3. Application Setup

```bash
# Create application directory
sudo mkdir -p /var/www/personal-finance-tracker
sudo chown -R $USER:$USER /var/www/personal-finance-tracker

# Copy your application files
cp -r /path/to/your/app/* /var/www/personal-finance-tracker/

# Install dependencies
cd /var/www/personal-finance-tracker
npm install

# Build the application
npm run build
```

### 4. Environment Configuration

Create `/var/www/personal-finance-tracker/.env`:

```env
NODE_ENV=production
DATABASE_URL=postgresql://finance_user:your_secure_password@localhost:5432/finance_tracker
PORT=3001
SESSION_SECRET=your_session_secret_here
PGHOST=localhost
PGPORT=5432
PGUSER=finance_user
PGPASSWORD=your_secure_password
PGDATABASE=finance_tracker
```

### 5. Database Schema

```bash
# Push database schema
cd /var/www/personal-finance-tracker
npm run db:push
```

### 6. PM2 Configuration

Create `/var/www/personal-finance-tracker/ecosystem.config.js`:

```javascript
module.exports = {
  apps: [{
    name: 'personal-finance-tracker',
    script: 'dist/index.js',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    instances: 1,
    exec_mode: 'cluster',
    max_memory_restart: '1G',
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    autorestart: true,
    watch: false
  }]
};
```

### 7. Start Application

```bash
# Create logs directory
mkdir -p /var/www/personal-finance-tracker/logs

# Start with PM2
cd /var/www/personal-finance-tracker
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 startup
pm2 startup
# Follow the instructions shown
```

### 8. Nginx Configuration

Create `/etc/nginx/sites-available/personal-finance-tracker`:

```nginx
server {
    listen 80;
    server_name your-domain.com;  # Change this to your domain

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;

    # Static file caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 9. Enable Site and SSL

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/personal-finance-tracker /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Install SSL certificate
sudo certbot --nginx -d your-domain.com
```

## Management Commands

### Check Status
```bash
pm2 status
pm2 logs personal-finance-tracker
sudo systemctl status nginx
```

### Restart Application
```bash
pm2 restart personal-finance-tracker
```

### View Logs
```bash
pm2 logs personal-finance-tracker --lines 50
sudo tail -f /var/log/nginx/error.log
```

### Update Application
```bash
cd /var/www/personal-finance-tracker
git pull  # if using git
npm install
npm run build
pm2 restart personal-finance-tracker
```

## Port Configuration

The application runs on port 3001 by default. You can change this in:
- `.env` file (PORT variable)
- `ecosystem.config.js` (env.PORT)
- Nginx configuration (proxy_pass)

## Security Considerations

1. **Firewall**: Ensure only necessary ports are open
2. **SSL**: Always use HTTPS in production
3. **Database**: Use strong passwords and limit access
4. **Updates**: Keep system and dependencies updated
5. **Backups**: Regular database backups

## Troubleshooting

### Common Issues

1. **Port already in use**: Check if port 3001 is available
2. **Database connection**: Verify PostgreSQL is running and credentials are correct
3. **Permission issues**: Ensure proper file ownership and permissions
4. **Nginx errors**: Check configuration syntax with `nginx -t`

### Log Locations

- Application logs: `/var/www/personal-finance-tracker/logs/`
- PM2 logs: `~/.pm2/logs/`
- Nginx logs: `/var/log/nginx/`
- PostgreSQL logs: `/var/log/postgresql/`

## Backup Strategy

### Database Backup
```bash
# Create backup
pg_dump -U finance_user -h localhost finance_tracker > backup.sql

# Restore backup
psql -U finance_user -h localhost finance_tracker < backup.sql
```

### Application Backup
```bash
# Backup application files
tar -czf finance-tracker-backup.tar.gz /var/www/personal-finance-tracker
```

## Performance Optimization

1. **Enable PM2 clustering** for multiple CPU cores
2. **Configure Nginx caching** for static assets
3. **Database indexing** for better query performance
4. **Monitor resource usage** with PM2 monitoring

## Support

For issues or questions, check:
- Application logs for errors
- Nginx error logs
- Database connection status
- PM2 process status

Remember to secure your environment variables and database credentials!