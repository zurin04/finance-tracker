# Personal Finance Tracker

## Overview

This is a full-stack web application for tracking personal finances, including daily income, expenses, bills, tasks, and goals with a calendar-based view for monitoring Profit & Loss (P&L) and task progress. The application provides a comprehensive dashboard for financial management and productivity tracking.

## System Architecture

### Frontend Architecture
- **Framework**: React 18 with TypeScript
- **Routing**: Wouter for lightweight client-side routing
- **UI Framework**: Radix UI components with shadcn/ui design system
- **Styling**: Tailwind CSS with custom CSS variables for theming
- **State Management**: TanStack Query for server state management and caching
- **Forms**: React Hook Form with Zod validation
- **Build Tool**: Vite for fast development and optimized builds

### Backend Architecture
- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js for REST API endpoints
- **Database**: PostgreSQL with Drizzle ORM for type-safe database operations
- **Database Provider**: Neon Database (serverless PostgreSQL)
- **Schema Management**: Drizzle Kit for migrations and schema management
- **Session Management**: Connect-pg-simple for PostgreSQL session storage

### Data Storage Solutions
- **Primary Database**: PostgreSQL hosted on Neon Database
- **ORM**: Drizzle ORM with PostgreSQL dialect
- **Schema**: Defined in shared/schema.ts with Zod validation schemas
- **Migration Strategy**: File-based migrations in ./migrations directory

## Key Components

### Database Schema
The application uses the following main entities:
- **Users**: Basic user management with username/password authentication
- **Income**: Financial income tracking with categories (goal/credit)
- **Expenses**: Expense tracking with categories and descriptions
- **Bills**: Bill management with due dates and payment status
- **Tasks**: Task management with priorities, categories, and goal linking
- **Goals**: Goal setting and progress tracking with target amounts

### API Structure
RESTful API endpoints organized by resource:
- `/api/income` - Income CRUD operations
- `/api/expenses` - Expense CRUD operations
- `/api/bills` - Bill management
- `/api/tasks` - Task management
- `/api/goals` - Goal tracking
- `/api/analytics` - P&L and statistical data

### Frontend Components
- **Dashboard**: Main overview with metrics and quick actions
- **Calendar View**: Interactive calendar showing daily events and P&L
- **Quick Add Forms**: Tabbed interface for rapid data entry
- **Today's Tasks**: Daily task management with completion tracking
- **Goals Progress**: Visual progress tracking for financial goals
- **Recent Transactions**: Timeline of recent financial activities

## Data Flow

1. **Client Requests**: React components use TanStack Query to fetch data
2. **API Layer**: Express routes handle HTTP requests and validate input
3. **Business Logic**: Storage interface abstracts database operations
4. **Database**: Drizzle ORM executes type-safe SQL queries against PostgreSQL
5. **Response**: JSON data flows back through the same path with proper error handling

## External Dependencies

### Production Dependencies
- **Database**: @neondatabase/serverless for serverless PostgreSQL connection
- **ORM**: drizzle-orm and drizzle-zod for database operations and validation
- **UI Components**: Extensive Radix UI component library
- **State Management**: @tanstack/react-query for server state
- **Form Management**: react-hook-form with @hookform/resolvers
- **Date Handling**: date-fns for date manipulation
- **Styling**: Tailwind CSS with class-variance-authority for component variants

### Development Dependencies
- **Build Tools**: Vite with TypeScript support
- **Code Generation**: drizzle-kit for schema management
- **Development Server**: tsx for TypeScript execution
- **Bundling**: esbuild for production builds

## Deployment Strategy

### Build Process
1. **Frontend Build**: Vite builds React application to `dist/public`
2. **Backend Build**: esbuild bundles server code to `dist/index.js`
3. **Database**: Drizzle Kit manages schema migrations

### Environment Configuration
- **Development**: Uses NODE_ENV=development with tsx for hot reloading
- **Production**: NODE_ENV=production with compiled JavaScript
- **Database**: DATABASE_URL environment variable for PostgreSQL connection

### Deployment Options

#### 1. VPS Deployment (Primary)
- **Script**: `deploy-production.sh` - One-click deployment for Ubuntu VPS
- **Components**: Node.js 20, PostgreSQL, Nginx, PM2, Certbot
- **Features**: Auto SSL, firewall setup, process management
- **Management**: `manage.sh` script for backup, update, logs
- **Requirements**: Ubuntu 20.04+, 2GB RAM, sudo access

#### 2. Replit Deployment (Development)
- **Native**: Uses Replit's built-in deployment system
- **Database**: Neon Database integration
- **Features**: Automatic HTTPS, custom domains
- **Management**: Replit dashboard and CLI

### Hosting Requirements
- Node.js runtime environment
- PostgreSQL database (Neon Database or self-hosted)
- Static file serving for frontend assets
- Reverse proxy for production (Nginx recommended)

## User Preferences

Preferred communication style: Simple, everyday language.

## Recent Changes

- **July 12, 2025**: Fixed deployment script PM2 configuration issues
  - Resolved inconsistent PM2 configurations between fix command and main deployment
  - Changed from npm wrapper to direct Node.js execution to prevent PM2 restart loops
  - Fixed PGPORT environment variable formatting for consistency
  - Standardized PM2 ecosystem.config.cjs across both deployment paths
  - Bill functionality confirmed working correctly through testing

- **July 10, 2025**: Mobile-first responsive design optimization and deployment fixes
  - Implemented mobile-responsive navigation header with hamburger menu and collapsible user info
  - Added responsive dashboard layout that switches to single-column stack on mobile devices
  - Enhanced all dashboard components with mobile-friendly padding, spacing, and touch targets
  - Optimized calendar view with abbreviated day names and smaller indicators for mobile
  - Added mobile-specific CSS utilities for touch interactions and safe area handling
  - Implemented mobile-optimized quick add forms with smaller tabs and responsive inputs
  - Enhanced task, transaction, and goal components with truncation and proper flex layouts
  - Added proper viewport meta tags and mobile web app capabilities
  - Integrated mobile sidebar with sheet overlay for notes navigation
  - Added touch manipulation and mobile scrollbar optimizations for better UX
  - Fixed server port configuration from 3001 to 5000 for Replit deployment compatibility

- **July 07, 2025**: Production-ready deployment script based on proven crypto platform reference
  - Rebuilt deploy.sh using tested patterns from successful crypto airdrop deployment
  - Added robust file copying, error handling, and dependency management
  - Integrated comprehensive fix command with database reset capabilities
  - Added secure credential generation and URL encoding for database passwords
  - Implemented memory optimization for builds and proper PM2 configuration
  - Added security headers and firewall configuration
  - Application runs on port 3001 with proper conflict detection
  - Ready for production deployment at finance.zaihash.xyz

- **July 07, 2025**: Single comprehensive deployment script for finance.zaihash.xyz
  - Created unified deploy.sh script that handles complete installation and fixes
  - Fixed PM2 restart loop issue by using direct node execution instead of npm wrapper
  - Implemented clean database reset with simple password to avoid connection string issues
  - Added build verification and comprehensive error handling throughout deployment
  - Configured port conflict detection (3001/3002) and Nginx virtual host routing
  - Included management script with status, logs, restart, fix, ssl, update, and backup commands
  - Removed all unnecessary deployment files for single-script approach

- **July 07, 2025**: Profile persistence and authentication fixes
  - Fixed JavaScript errors that prevented user profile data from displaying in navigation header
  - Enhanced authentication flow for both email/password and Web3 wallet login
  - Added proper query invalidation to ensure user data consistency after login
  - Resolved frontend caching issues that caused profile information loss after logout/login cycles
  - Confirmed profile data persistence working correctly for all authentication methods

- **July 07, 2025**: Consolidated into single comprehensive deployment script
  - Merged all enhancements into single `deploy-production.sh` with advanced error handling
  - Added system requirements validation, memory optimization, and security features
  - Implemented proper error cleanup and recovery mechanisms
  - Enhanced firewall configuration and intrusion prevention
  - Addressed dual dashboard rendering issue with fixed positioning layout
  - Removed redundant deployment files to maintain single script approach
  
- **July 07, 2025**: Project cleanup and streamlined deployment
  - Removed all unnecessary deployment files and guides (DEPLOYMENT.md, TROUBLESHOOTING.md, docker files, etc.)
  - Created single streamlined `deploy-production.sh` script based on crypto airdrop platform reference
  - Simplified project structure with only essential files
  - Updated README.md to reflect cleaned-up deployment process
  - Fixed database connection issues by provisioning PostgreSQL database
  - Created comprehensive one-click deployment script with automatic SSL, backups, and management

- **July 06, 2025**: Currency settings feature added
  - Added currency field to user schema with USD and PHP support
  - Created useCurrency hook for consistent currency formatting throughout the app
  - Updated profile settings to include currency selection dropdown
  - Enhanced all financial forms and displays to show user's preferred currency symbol
  - Implemented proper currency formatting with Intl.NumberFormat for both USD and PHP

- **July 06, 2025**: Authentication flow improvements
  - Fixed Web3 login routing issue that caused 404 errors after successful authentication
  - Replaced window.location.href with proper Wouter router navigation
  - Enhanced routing logic to handle authentication state transitions smoothly
  - Improved authentication query caching for better user experience

- **July 06, 2025**: Database configuration improvements for production
  - Fixed PostgreSQL session store warning by replacing in-memory store with proper PostgreSQL session store
  - Updated database configuration to support both connection string and individual parameter methods
  - Enhanced production database connection handling to avoid URL parsing issues with special characters
  - Created production database fix guide for handling passwords with special characters
  - Sessions now persist across server restarts eliminating memory leaks

- **July 06, 2025**: Calendar integration with notes and diary entries completed
  - Added visual indicators for notes (indigo) and diary entries (purple) on calendar
  - Enhanced date details dialog to display full note content with categories and tags
  - Integrated notes data fetching into calendar view component
  - Updated calendar legend to include notes and diary indicators

## Changelog

- **July 06, 2025**: Initial setup and core features development
- **July 06, 2025**: Calendar integration with notes system completed
- **July 06, 2025**: Production deployment infrastructure added