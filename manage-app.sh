#!/bin/bash

# Personal Finance Tracker Management Script
# Usage: ./manage-app.sh [command]

APP_NAME="personal-finance-tracker"
APP_DIR="/var/www/$APP_NAME"
DB_NAME="finance_tracker"
DB_USER="finance_user"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

show_usage() {
    echo "Personal Finance Tracker Management Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  status     - Show application and system status"
    echo "  start      - Start the application"
    echo "  stop       - Stop the application"
    echo "  restart    - Restart the application"
    echo "  logs       - Show application logs"
    echo "  update     - Update the application"
    echo "  backup     - Create database backup"
    echo "  restore    - Restore database from backup"
    echo "  ssl        - Renew SSL certificate"
    echo "  monitor    - Monitor application performance"
    echo "  fix        - Fix common issues"
    echo "  help       - Show this help message"
}

check_status() {
    print_status "Checking application status..."
    
    echo "=== PM2 STATUS ==="
    pm2 status 2>/dev/null || print_warning "PM2 not running"
    echo ""
    
    echo "=== APPLICATION PROCESS ==="
    if pgrep -f "$APP_NAME" > /dev/null; then
        print_success "Application is running"
        echo "Process ID: $(pgrep -f "$APP_NAME")"
    else
        print_error "Application is not running"
    fi
    echo ""
    
    echo "=== PORT STATUS ==="
    APP_PORT=$(grep "PORT=" $APP_DIR/.env 2>/dev/null | cut -d'=' -f2 || echo "3001")
    if netstat -tlnp | grep ":$APP_PORT" > /dev/null; then
        print_success "Port $APP_PORT is in use"
    else
        print_warning "Port $APP_PORT is not in use"
    fi
    echo ""
    
    echo "=== DATABASE STATUS ==="
    if systemctl is-active --quiet postgresql; then
        print_success "PostgreSQL is running"
        if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
            print_success "Database $DB_NAME exists"
        else
            print_error "Database $DB_NAME does not exist"
        fi
    else
        print_error "PostgreSQL is not running"
    fi
    echo ""
    
    echo "=== NGINX STATUS ==="
    if systemctl is-active --quiet nginx; then
        print_success "Nginx is running"
        if [ -f "/etc/nginx/sites-enabled/$APP_NAME" ]; then
            print_success "Nginx configuration is active"
        else
            print_warning "Nginx configuration not found"
        fi
    else
        print_error "Nginx is not running"
    fi
    echo ""
    
    echo "=== DISK USAGE ==="
    df -h $APP_DIR 2>/dev/null || print_warning "Cannot check disk usage"
    echo ""
    
    echo "=== MEMORY USAGE ==="
    free -h
}

start_app() {
    print_status "Starting application..."
    
    if [ ! -d "$APP_DIR" ]; then
        print_error "Application directory not found: $APP_DIR"
        exit 1
    fi
    
    cd $APP_DIR
    
    # Check if already running
    if pm2 list | grep -q "$APP_NAME"; then
        print_warning "Application is already running"
        pm2 restart $APP_NAME
    else
        pm2 start ecosystem.config.js
    fi
    
    print_success "Application started"
}

stop_app() {
    print_status "Stopping application..."
    
    pm2 stop $APP_NAME 2>/dev/null || print_warning "Application was not running"
    pm2 delete $APP_NAME 2>/dev/null || true
    
    print_success "Application stopped"
}

restart_app() {
    print_status "Restarting application..."
    
    if [ ! -d "$APP_DIR" ]; then
        print_error "Application directory not found: $APP_DIR"
        exit 1
    fi
    
    cd $APP_DIR
    pm2 restart $APP_NAME 2>/dev/null || pm2 start ecosystem.config.js
    
    print_success "Application restarted"
}

show_logs() {
    print_status "Showing application logs..."
    
    echo "=== PM2 LOGS ==="
    pm2 logs $APP_NAME --lines 50 2>/dev/null || print_warning "No PM2 logs available"
    echo ""
    
    echo "=== APPLICATION LOG FILES ==="
    if [ -d "$APP_DIR/logs" ]; then
        echo "Recent errors:"
        tail -20 $APP_DIR/logs/err.log 2>/dev/null || print_warning "No error logs"
        echo ""
        echo "Recent output:"
        tail -20 $APP_DIR/logs/out.log 2>/dev/null || print_warning "No output logs"
    else
        print_warning "Log directory not found"
    fi
    echo ""
    
    echo "=== NGINX LOGS ==="
    echo "Recent errors:"
    sudo tail -10 /var/log/nginx/error.log 2>/dev/null || print_warning "No Nginx error logs"
    echo ""
    echo "Recent access:"
    sudo tail -10 /var/log/nginx/access.log 2>/dev/null || print_warning "No Nginx access logs"
}

update_app() {
    print_status "Updating application..."
    
    if [ ! -d "$APP_DIR" ]; then
        print_error "Application directory not found: $APP_DIR"
        exit 1
    fi
    
    cd $APP_DIR
    
    # Stop application
    pm2 stop $APP_NAME 2>/dev/null || true
    
    # Pull latest changes (if using git)
    if [ -d ".git" ]; then
        print_status "Pulling latest changes..."
        git pull
    else
        print_warning "Not a git repository. Manual update required."
    fi
    
    # Install dependencies
    print_status "Installing dependencies..."
    npm install --production
    
    # Build application
    print_status "Building application..."
    npm run build
    
    # Restart application
    pm2 start ecosystem.config.js
    
    print_success "Application updated and restarted"
}

backup_db() {
    print_status "Creating database backup..."
    
    BACKUP_DIR="$APP_DIR/backups"
    BACKUP_FILE="$BACKUP_DIR/backup-$(date +%Y%m%d_%H%M%S).sql"
    
    mkdir -p $BACKUP_DIR
    
    if [ -f "$APP_DIR/.env" ]; then
        source $APP_DIR/.env
        pg_dump -U $DB_USER -h localhost $DB_NAME > $BACKUP_FILE
        print_success "Database backup created: $BACKUP_FILE"
        
        # Keep only last 7 backups
        find $BACKUP_DIR -name "backup-*.sql" -mtime +7 -delete
    else
        print_error "Environment file not found: $APP_DIR/.env"
    fi
}

restore_db() {
    print_status "Restoring database from backup..."
    
    if [ -z "$2" ]; then
        print_error "Usage: $0 restore [backup_file]"
        exit 1
    fi
    
    BACKUP_FILE="$2"
    
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    
    if [ -f "$APP_DIR/.env" ]; then
        source $APP_DIR/.env
        
        print_warning "This will overwrite the current database. Continue? [y/N]"
        read -r confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            psql -U $DB_USER -h localhost $DB_NAME < $BACKUP_FILE
            print_success "Database restored from: $BACKUP_FILE"
        else
            print_status "Restore cancelled"
        fi
    else
        print_error "Environment file not found: $APP_DIR/.env"
    fi
}

renew_ssl() {
    print_status "Renewing SSL certificate..."
    
    sudo certbot renew --nginx
    sudo systemctl reload nginx
    
    print_success "SSL certificate renewed"
}

monitor_app() {
    print_status "Monitoring application performance..."
    
    pm2 monit
}

fix_issues() {
    print_status "Fixing common issues..."
    
    # Check if app directory exists
    if [ ! -d "$APP_DIR" ]; then
        print_error "Application directory not found: $APP_DIR"
        exit 1
    fi
    
    cd $APP_DIR
    
    # Stop all processes
    pm2 delete $APP_NAME 2>/dev/null || true
    pkill -f "$APP_NAME" 2>/dev/null || true
    
    # Check and fix permissions
    print_status "Fixing permissions..."
    sudo chown -R $USER:$USER $APP_DIR
    chmod +x $APP_DIR/manage-app.sh 2>/dev/null || true
    
    # Reinstall dependencies
    print_status "Reinstalling dependencies..."
    rm -rf node_modules package-lock.json
    npm install --production
    
    # Rebuild application
    print_status "Rebuilding application..."
    npm run build
    
    # Restart services
    print_status "Restarting services..."
    sudo systemctl restart postgresql
    sudo systemctl restart nginx
    
    # Start application
    pm2 start ecosystem.config.js
    
    print_success "Issues fixed and application restarted"
}

# Main script logic
case "$1" in
    "status")
        check_status
        ;;
    "start")
        start_app
        ;;
    "stop")
        stop_app
        ;;
    "restart")
        restart_app
        ;;
    "logs")
        show_logs
        ;;
    "update")
        update_app
        ;;
    "backup")
        backup_db
        ;;
    "restore")
        restore_db "$@"
        ;;
    "ssl")
        renew_ssl
        ;;
    "monitor")
        monitor_app
        ;;
    "fix")
        fix_issues
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        show_usage
        exit 1
        ;;
esac