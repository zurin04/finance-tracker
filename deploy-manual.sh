#!/bin/bash

# Personal Finance Tracker - Manual VPS Deployment Script
# For deployment alongside other web applications

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="personal-finance-tracker"
APP_USER="finance"
APP_PORT="3001"
APP_DIR="/var/www/$APP_NAME"
NGINX_CONFIG="/etc/nginx/sites-available/$APP_NAME"
DOMAIN="your-domain.com"  # Change this to your domain
SUBDOMAIN="finance.$DOMAIN"  # Or use a subdomain

# Database configuration
DB_NAME="finance_tracker"
DB_USER="finance_user"
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi

print_status "Starting Personal Finance Tracker deployment..."

# Update system packages
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install Node.js 20 if not already installed
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
else
    print_success "Node.js already installed: $(node --version)"
fi

# Install PostgreSQL if not already installed
if ! command -v psql &> /dev/null; then
    print_status "Installing PostgreSQL..."
    apt-get install -y postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
else
    print_success "PostgreSQL already installed"
fi

# Install PM2 globally if not already installed
if ! command -v pm2 &> /dev/null; then
    print_status "Installing PM2..."
    npm install -g pm2
else
    print_success "PM2 already installed"
fi

# Install Nginx if not already installed
if ! command -v nginx &> /dev/null; then
    print_status "Installing Nginx..."
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
else
    print_success "Nginx already installed"
fi

# Create application user
if ! id "$APP_USER" &>/dev/null; then
    print_status "Creating application user: $APP_USER"
    useradd -m -s /bin/bash $APP_USER
    usermod -aG sudo $APP_USER
else
    print_success "User $APP_USER already exists"
fi

# Create application directory
print_status "Setting up application directory..."
mkdir -p $APP_DIR
chown -R $APP_USER:$APP_USER $APP_DIR

# Setup PostgreSQL database
print_status "Setting up PostgreSQL database..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" || true
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" || true
sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;" || true

# Copy application files
print_status "Copying application files..."
cp -r ./* $APP_DIR/
chown -R $APP_USER:$APP_USER $APP_DIR

# Create environment file
print_status "Creating environment configuration..."
cat > $APP_DIR/.env << EOF
NODE_ENV=production
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
PORT=$APP_PORT
SESSION_SECRET=$(openssl rand -base64 32)
PGHOST=localhost
PGPORT=5432
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME
EOF

chown $APP_USER:$APP_USER $APP_DIR/.env
chmod 600 $APP_DIR/.env

# Install dependencies and build
print_status "Installing dependencies and building application..."
cd $APP_DIR
sudo -u $APP_USER npm install --production
sudo -u $APP_USER npm run build

# Push database schema
print_status "Setting up database schema..."
sudo -u $APP_USER npm run db:push

# Create PM2 ecosystem file
print_status "Creating PM2 configuration..."
cat > $APP_DIR/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: '$APP_NAME',
    script: 'dist/index.js',
    env: {
      NODE_ENV: 'production',
      PORT: $APP_PORT
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
EOF

chown $APP_USER:$APP_USER $APP_DIR/ecosystem.config.js

# Create logs directory
mkdir -p $APP_DIR/logs
chown -R $APP_USER:$APP_USER $APP_DIR/logs

# Start application with PM2
print_status "Starting application with PM2..."
cd $APP_DIR
sudo -u $APP_USER pm2 start ecosystem.config.js
sudo -u $APP_USER pm2 save
sudo -u $APP_USER pm2 startup | tail -n 1 | bash

# Create Nginx configuration
print_status "Creating Nginx configuration..."
cat > $NGINX_CONFIG << 'EOF'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;

    location / {
        proxy_pass http://localhost:PORT_PLACEHOLDER;
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
EOF

# Replace placeholders in Nginx config
sed -i "s/DOMAIN_PLACEHOLDER/$SUBDOMAIN/g" $NGINX_CONFIG
sed -i "s/PORT_PLACEHOLDER/$APP_PORT/g" $NGINX_CONFIG

# Enable site
ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

# Setup firewall rules
print_status "Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow $APP_PORT/tcp
ufw --force enable

print_success "Deployment completed successfully!"
print_status "Application Details:"
echo "- App Name: $APP_NAME"
echo "- App User: $APP_USER"
echo "- App Directory: $APP_DIR"
echo "- App Port: $APP_PORT"
echo "- Domain: $SUBDOMAIN"
echo "- Database: $DB_NAME"
echo "- Database User: $DB_USER"
echo "- Database Password: $DB_PASSWORD"

print_status "Next Steps:"
echo "1. Update DNS records to point $SUBDOMAIN to your server IP"
echo "2. Install SSL certificate with certbot:"
echo "   certbot --nginx -d $SUBDOMAIN"
echo "3. Check application status: pm2 status"
echo "4. Check logs: pm2 logs $APP_NAME"
echo "5. Restart application: pm2 restart $APP_NAME"

print_warning "Important: Save the database password: $DB_PASSWORD"
print_success "Access your application at: http://$SUBDOMAIN"