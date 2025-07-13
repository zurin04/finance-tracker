#!/bin/bash

# Personal Finance Tracker - Complete VPS Deployment Script
# One-click deployment and management for main domain on port 5000

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
APP_NAME="personal-finance-tracker"
APP_DIR="/var/www/$APP_NAME"
DB_NAME="personal_finance_db"
DB_USER="finance_user"
APP_PORT=5000

# Management commands
if [ "$1" = "status" ]; then
    echo "=== PM2 STATUS ==="
    pm2 status 2>/dev/null || echo "PM2 not running"
    echo ""
    echo "=== PORT USAGE ==="
    ss -tlnp | grep -E ":(80|443|5000)" || echo "No relevant ports in use"
    echo ""
    echo "=== NGINX STATUS ==="
    sudo systemctl status nginx --no-pager -l | head -5
    echo ""
    echo "=== DATABASE STATUS ==="
    sudo systemctl status postgresql --no-pager -l | head -5
    exit 0
elif [ "$1" = "logs" ]; then
    pm2 logs $APP_NAME --lines 50 2>/dev/null || echo "No PM2 logs available"
    echo ""
    echo "=== NGINX LOGS ==="
    sudo tail -10 /var/log/nginx/error.log 2>/dev/null || echo "No Nginx errors"
    exit 0
elif [ "$1" = "restart" ]; then
    if [ -d "$APP_DIR" ]; then
        cd $APP_DIR && pm2 restart $APP_NAME
        print_status "Application restarted"
    else
        print_error "App directory not found. Run ./deploy.sh first."
    fi
    exit 0
elif [ "$1" = "fix" ]; then
    print_status "Fixing application issues..."
    
    # Check if app directory exists
    if [ ! -d "$APP_DIR" ]; then
        print_error "App directory $APP_DIR not found. Run ./deploy.sh first."
        exit 1
    fi
    
    cd $APP_DIR
    
    # Show current error logs
    print_status "Current error logs:"
    pm2 logs $APP_NAME --lines 10 2>/dev/null || echo "No PM2 logs available"
    
    # Stop all processes
    pm2 delete $APP_NAME 2>/dev/null || true
    pkill -f "node.*dist" 2>/dev/null || true
    
    # Get existing password or generate new one
    if [ -f ".env" ]; then
        source .env
        DB_PASSWORD=${PGPASSWORD:-$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)}
    else
        DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
    fi
    
    # Create environment with port 5000
    cat > .env << EOF
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
SESSION_SECRET=finance-secret-$(date +%s)
NODE_ENV=production
PORT=5000
PGHOST=localhost
PGPORT=5432
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME
EOF
    
    # Rebuild if needed
    if [ ! -f "dist/index.js" ]; then
        print_status "Building application..."
        export NODE_OPTIONS="--max-old-space-size=2048"
        npm run build || {
            print_error "Build failed"
            npm run build 2>&1 | tail -20
            exit 1
        }
    fi
    
    # Test database connection
    if ! PGPASSWORD="$DB_PASSWORD" psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1;" >/dev/null 2>&1; then
        print_warning "Database connection failed, recreating..."
        sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD' SUPERUSER;
CREATE DATABASE $DB_NAME OWNER $DB_USER;
\q
EOF
        export DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
        npm run db:push
    fi
    
    # Test manual start first
    print_status "Testing manual start..."
    timeout 10s node dist/index.js &
    MANUAL_PID=$!
    sleep 5
    
    if ss -tlnp | grep -q ":5000"; then
        print_status "✓ Manual start successful"
        kill $MANUAL_PID 2>/dev/null || true
    else
        print_error "✗ Manual start failed:"
        kill $MANUAL_PID 2>/dev/null || true
        echo "Error output:"
        timeout 5s node dist/index.js 2>&1 | head -5
        exit 1
    fi
    
    # Update PM2 config
    cat > ecosystem.config.cjs << EOF
module.exports = {
  apps: [{
    name: '$APP_NAME',
    script: 'dist/index.js',
    cwd: '$APP_DIR',
    env: {
      NODE_ENV: 'production',
      PORT: 5000,
      DATABASE_URL: 'postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME',
      SESSION_SECRET: 'finance-secret-$(date +%s)',
      PGHOST: 'localhost',
      PGPORT: '5432',
      PGUSER: '$DB_USER',
      PGPASSWORD: '$DB_PASSWORD',
      PGDATABASE: '$DB_NAME'
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    min_uptime: '10s',
    max_restarts: 10,
    restart_delay: 5000
  }]
};
EOF
    
    # Start application
    pm2 start ecosystem.config.cjs
    pm2 save
    sleep 5
    
    # Verify everything works
    if pm2 list | grep -q "$APP_NAME.*online"; then
        print_status "✓ PM2 application online"
    else
        print_error "✗ PM2 application failed"
        pm2 logs $APP_NAME --lines 5
        exit 1
    fi
    
    if ss -tlnp | grep -q ":5000"; then
        print_status "✓ Application running on port 5000"
    else
        print_error "✗ Application not running on port 5000"
        exit 1
    fi
    
    if curl -s http://localhost:5000 >/dev/null 2>&1; then
        print_status "✓ Application responding"
    else
        print_error "✗ Application not responding"
        exit 1
    fi
    
    # Test Nginx proxy
    if curl -s http://localhost:80 >/dev/null 2>&1; then
        print_status "✓ Nginx proxy working"
    else
        print_warning "✗ Nginx proxy issue - check configuration"
    fi
    
    SERVER_IP=$(curl -s -m 3 ifconfig.me 2>/dev/null || echo "Unknown")
    print_status "Application fixed and running!"
    echo "Access at: http://$SERVER_IP"
    exit 0
fi

# Main deployment process
echo "======================================"
echo "Personal Finance Tracker Deployment"
echo "Main Domain - Port 5000"
echo "======================================"

# Check prerequisites
[[ $EUID -eq 0 ]] && { print_error "Don't run as root. Use sudo user."; exit 1; }
command -v sudo >/dev/null || { print_error "sudo required"; exit 1; }

# System requirements check
print_status "Checking system requirements..."
MEMORY_MB=$(free -m | grep '^Mem:' | awk '{print $2}')
if [ "$MEMORY_MB" -lt 1000 ]; then
    print_warning "Low memory detected (${MEMORY_MB}MB < 1GB). Build may fail."
fi

# Check if we're in the project directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found! Run from project directory."
    exit 1
fi

# Update system
print_status "Updating system packages..."
sudo apt update -y

# Install Node.js 20
if ! command -v node &>/dev/null || [ "$(node --version | cut -d'v' -f2 | cut -d'.' -f1)" -lt 18 ]; then
    print_status "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Install system dependencies
print_status "Installing system dependencies..."
sudo apt install -y postgresql postgresql-contrib nginx build-essential python3 curl wget gnupg lsb-release

# Install PM2 globally
if ! command -v pm2 &>/dev/null; then
    print_status "Installing PM2..."
    sudo npm install -g pm2
fi

# Start and enable services
print_status "Starting system services..."
sudo systemctl enable --now postgresql
sudo systemctl enable --now nginx

# Setup application directory
print_status "Setting up application directory..."
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Copy application files
print_status "Copying application files..."
cp -r . $APP_DIR/
cd $APP_DIR

# Remove git directory to save space
rm -rf .git 2>/dev/null || true

# Generate secure credentials
print_status "Generating secure credentials..."
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
SESSION_SECRET=$(openssl rand -hex 32)

# Setup PostgreSQL database
print_status "Setting up PostgreSQL database..."
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD' SUPERUSER;
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\q
EOF

# Create environment file
print_status "Creating environment configuration..."
cat > .env << EOF
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
SESSION_SECRET=$SESSION_SECRET
NODE_ENV=production
PORT=5000
PGHOST=localhost
PGPORT=5432
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME
EOF

# Install dependencies
print_status "Installing application dependencies..."
npm install

# Setup database schema
print_status "Setting up database schema..."

# URL encode the password to handle special characters
if command -v python3 >/dev/null 2>&1; then
    DB_PASSWORD_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$DB_PASSWORD', safe=''))")
else
    print_warning "Python3 not available, using password as-is (may cause issues with special characters)"
    DB_PASSWORD_ENCODED="$DB_PASSWORD"
fi

export DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD_ENCODED@localhost:5432/$DB_NAME"
export SESSION_SECRET="$SESSION_SECRET"
export NODE_ENV=production
export PORT=5000

# Test database connection
print_status "Testing database connection..."
if ! PGPASSWORD="$DB_PASSWORD" psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1;" >/dev/null 2>&1; then
    print_error "Database connection failed"
    exit 1
fi

print_status "Pushing database schema..."
# Try with encoded URL first, then fallback to direct connection
if ! npm run db:push 2>&1; then
    print_warning "Schema push with encoded URL failed, trying direct connection..."
    export DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
    if ! npm run db:push 2>&1; then
        print_error "Database schema push failed with both URL formats."
        exit 1
    fi
fi

# Update .env file with working DATABASE_URL
print_status "Updating environment configuration with working database URL..."
cat > .env << EOF
DATABASE_URL=$DATABASE_URL
SESSION_SECRET=$SESSION_SECRET
NODE_ENV=production
PORT=5000
PGHOST=localhost
PGPORT=5432
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME
EOF

# Build application with extended timeout and memory optimization
print_status "Building application..."
export NODE_OPTIONS="--max-old-space-size=4096"
timeout 600 npm run build || {
    print_warning "Build timed out or failed, trying fallback strategy..."
    # Fallback strategy for resource-constrained VPS
    export NODE_OPTIONS="--max-old-space-size=2048"
    timeout 300 npm run build || {
        print_error "Build failed even with fallback strategy. Check available memory and try building locally."
        exit 1
    }
}

# Verify build
if [ ! -f "dist/index.js" ]; then
    print_error "Build failed - dist/index.js not found"
    npm run build 2>&1 | tail -20
    exit 1
fi
print_status "Build completed successfully"

# Test manual start to catch errors
print_status "Testing application startup..."
timeout 10s node dist/index.js &
MANUAL_PID=$!
sleep 5

if ss -tlnp | grep -q ":5000"; then
    print_status "✓ Manual start successful - application uses port 5000"
    kill $MANUAL_PID 2>/dev/null || true
else
    print_error "✗ Manual start failed - showing error:"
    kill $MANUAL_PID 2>/dev/null || true
    echo "Error output:"
    timeout 5s node dist/index.js 2>&1 | head -10
    exit 1
fi

# Configure PM2 and services
print_status "Configuring PM2 and services..."
mkdir -p logs

# Determine which URL format worked
WORKING_DB_URL="$DATABASE_URL"

cat > ecosystem.config.cjs << EOF
module.exports = {
  apps: [{
    name: '$APP_NAME',
    script: 'dist/index.js',
    cwd: '$APP_DIR',
    env: {
      NODE_ENV: 'production',
      PORT: 5000,
      DATABASE_URL: '$WORKING_DB_URL',
      SESSION_SECRET: '$SESSION_SECRET',
      PGHOST: 'localhost',
      PGPORT: '5432',
      PGUSER: '$DB_USER',
      PGPASSWORD: '$DB_PASSWORD',
      PGDATABASE: '$DB_NAME'
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    min_uptime: '10s',
    max_restarts: 10,
    restart_delay: 5000,
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log'
  }]
};
EOF

# Configure Nginx for main domain
print_status "Configuring Nginx for main domain..."
sudo tee /etc/nginx/sites-available/$APP_NAME > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 100M;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
    }
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob:;";
}
EOF

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
if sudo nginx -t; then
    print_status "✓ Nginx configuration valid"
    sudo systemctl reload nginx
else
    print_error "✗ Nginx configuration invalid"
    sudo nginx -t
    exit 1
fi

# Create log directory
sudo mkdir -p /var/log
sudo touch /var/log/$APP_NAME-error.log /var/log/$APP_NAME-out.log /var/log/$APP_NAME.log
sudo chown $USER:$USER /var/log/$APP_NAME-*.log

# Start application with PM2
print_status "Starting application with PM2..."
pm2 delete all 2>/dev/null || true
pm2 start ecosystem.config.cjs
pm2 save

# Setup PM2 startup
print_status "Configuring PM2 auto-startup..."
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp $HOME

# Wait for application to start
print_status "Waiting for application to start..."
sleep 10

# Comprehensive verification
print_status "Verifying deployment..."

# Check PM2 status
if pm2 list | grep -q "$APP_NAME.*online"; then
    print_status "✓ PM2 application is online"
else
    print_error "✗ PM2 application failed to start"
    pm2 logs $APP_NAME --lines 10
    exit 1
fi

# Check port 5000
if ss -tlnp | grep -q ":5000"; then
    print_status "✓ Application listening on port 5000"
else
    print_error "✗ Application not listening on port 5000"
    pm2 logs $APP_NAME --lines 5
    exit 1
fi

# Test local connectivity
if curl -s -f http://localhost:5000 >/dev/null 2>&1; then
    print_status "✓ Application responds locally"
else
    print_error "✗ Application not responding locally"
    curl -s http://localhost:5000 2>&1 | head -3
    exit 1
fi

# Test Nginx proxy
if curl -s -f http://localhost:80 >/dev/null 2>&1; then
    print_status "✓ Nginx proxy working"
else
    print_error "✗ Nginx proxy not working"
    sudo journalctl -u nginx --lines 3
    exit 1
fi

# Setup security and firewall
print_status "Configuring security and firewall..."
sudo ufw --force enable
sudo ufw allow 22,80,443/tcp

# Get server info
SERVER_IP=$(curl -s -m 5 ifconfig.me 2>/dev/null || curl -s -m 5 icanhazip.com 2>/dev/null || echo "Unable to detect")

echo ""
echo "========================================"
echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "========================================"
echo ""
echo "Your Personal Finance Tracker is now running:"
echo ""
echo "📱 Main Domain Access: http://$SERVER_IP"
echo "🖥️  Direct Access: http://$SERVER_IP:5000"
echo ""
echo "📊 Application Status:"
echo "   • Port: 5000"
echo "   • Database: PostgreSQL"
echo "   • Process Manager: PM2"
echo "   • Web Server: Nginx"
echo "   • Mobile Optimized: Yes"
echo ""
echo "🔧 Management Commands:"
echo "   ./deploy.sh status   - Check application status"
echo "   ./deploy.sh logs     - View application logs"
echo "   ./deploy.sh restart  - Restart application"
echo "   ./deploy.sh fix      - Fix common issues"
echo ""
echo "📋 Next Steps:"
echo "   1. Access your app at: http://$SERVER_IP"
echo "   2. Create your first user account"
echo "   3. Start tracking your finances!"
echo ""
echo "🔒 For HTTPS/SSL setup:"
echo "   sudo certbot --nginx -d yourdomain.com"
echo ""
print_status "Deployment complete! Your mobile-optimized finance tracker is ready."

# Create enhanced management script
print_status "Creating management script..."
cat > manage.sh << 'SCRIPT'
#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

BACKUP_DIR="/var/backups/personal-finance-tracker"
APP_DIR="/var/www/personal-finance-tracker"

backup_database() {
    mkdir -p $BACKUP_DIR
    BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"
    echo "Creating database backup..."
    
    if PGPASSWORD="$PGPASSWORD" pg_dump -h localhost -U $PGUSER $PGDATABASE > $BACKUP_FILE; then
        echo "✓ Backup saved to: $BACKUP_FILE"
        # Keep only last 7 backups
        ls -t $BACKUP_DIR/backup_*.sql | tail -n +8 | xargs -r rm
        echo "✓ Old backups cleaned up (keeping last 7)"
    else
        echo "✗ Backup failed!"
        exit 1
    fi
}

ssl_setup() {
    local domain=$2
    if [ -z "$domain" ]; then
        echo "Usage: $0 ssl yourdomain.com"
        exit 1
    fi
    
    echo "Setting up SSL for domain: $domain"
    
    # Update Nginx config
    sudo sed -i "s/server_name _;/server_name $domain;/" /etc/nginx/sites-available/personal-finance-tracker
    sudo nginx -t && sudo systemctl reload nginx
    
    # Get SSL certificate
    if sudo certbot --nginx -d "$domain" --non-interactive --agree-tos --email "admin@$domain" --redirect; then
        echo "✓ SSL certificate installed successfully!"
        # Setup automatic renewal
        (sudo crontab -l 2>/dev/null | grep -v "certbot renew"; echo "0 12 * * * /usr/bin/certbot renew --quiet") | sudo crontab -
        echo "✓ SSL certificate auto-renewal configured"
    else
        echo "✗ SSL setup failed!"
        exit 1
    fi
}

case $1 in
    backup)
        backup_database
        ;;
    ssl)
        ssl_setup "$@"
        ;;
    status)
        echo "=== APPLICATION STATUS ==="
        pm2 status
        echo ""
        echo "=== SYSTEM STATUS ==="
        df -h | head -2
        free -h
        ;;
    logs)
        pm2 logs personal-finance-tracker --lines 50
        ;;
    restart)
        pm2 restart personal-finance-tracker
        ;;
    *)
        echo "Personal Finance Tracker Management Script"
        echo "Usage: $0 {backup|ssl|status|logs|restart}"
        echo ""
        echo "Commands:"
        echo "  backup              - Create database backup"
        echo "  ssl domain.com      - Setup SSL certificate"
        echo "  status              - Show application status"
        echo "  logs                - View application logs"
        echo "  restart             - Restart application"
        ;;
esac
SCRIPT

chmod +x manage.sh

echo ""
echo "📋 Management Tools Created:"
echo "   ./manage.sh backup        - Create database backup"
echo "   ./manage.sh ssl domain    - Setup SSL certificate"
echo "   ./manage.sh status        - Show detailed status"
echo "   ./manage.sh logs          - View application logs"
echo "   ./manage.sh restart       - Restart application"