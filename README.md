# Personal Finance Tracker

A comprehensive web application for tracking personal finances, including daily income, expenses, bills, tasks, and goals with an integrated notes/diary system and interactive calendar view.

## Features

- 📊 **Financial Tracking**: Income, expenses, bills, and goals management
- 📅 **Interactive Calendar**: Visual calendar with clickable dates showing daily activities
- 📝 **Notes & Diary System**: Notion-like notes with categories, tags, and daily diary entries
- 🔐 **Authentication**: User accounts with Web3 wallet login support
- 👤 **Profile Management**: Edit profile information and system settings
- 📱 **Responsive Design**: Works on desktop and mobile devices
- 🌙 **Dark Mode**: Toggle between light and dark themes

## Technology Stack

### Frontend
- **React 18** with TypeScript
- **Vite** for fast development and builds
- **Tailwind CSS** for styling
- **Radix UI** for accessible components
- **TanStack Query** for data fetching and caching
- **React Hook Form** with Zod validation

### Backend
- **Node.js 20** with Express
- **PostgreSQL** database with Drizzle ORM
- **Session-based authentication**
- **RESTful API** design

## Quick Start

### Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd personal-finance-tracker
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

4. **Start development server**
   ```bash
   npm run dev
   ```

The application will be available at `http://localhost:5000`

## 🚀 One-Click VPS Deployment

Deploy to your VPS with a single comprehensive script:

```bash
# Make script executable
chmod +x deploy-production.sh

# Run complete deployment
./deploy-production.sh
```

### ✅ Complete Setup
- **System**: Node.js 20, PostgreSQL, Nginx, PM2, security tools
- **Database**: Secure setup with random credentials
- **Application**: Full build and deployment with error handling
- **Security**: Firewall, fail2ban, SSL-ready configuration
- **Monitoring**: Comprehensive logging and process management

### 🔧 Advanced Features
- Memory optimization based on VPS specs
- Comprehensive error handling with cleanup
- Health checks and connectivity verification
- System requirements validation
- Automated backup management

### 📋 Management Commands
```bash
./manage.sh status    # Check application status
./manage.sh logs      # View logs
./manage.sh backup    # Create database backup
./manage.sh restart   # Restart application
./manage.sh ssl       # Setup SSL certificate
```

### 📋 Requirements
- Ubuntu 20.04+ VPS
- 2GB+ RAM recommended
- 5GB+ available disk space
- Non-root user with sudo privileges

## Database Schema

### Core Tables
- **users**: User accounts and authentication
- **income**: Income tracking with categories
- **expenses**: Expense tracking with categories
- **bills**: Bill management with due dates
- **tasks**: Task management with priorities
- **goals**: Goal setting and progress tracking
- **notes**: Notes and diary entries with tags

### Database Operations
```bash
npm run db:push    # Push schema changes
npm run db:studio  # Open Drizzle Studio (if available)
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/web3-login` - Web3 wallet login
- `POST /api/auth/register` - User registration
- `GET /api/auth/user` - Get current user
- `POST /api/auth/logout` - Logout user

### Financial Data
- `GET /api/income` - Get all income
- `POST /api/income` - Create income entry
- `GET /api/expenses` - Get all expenses
- `POST /api/expenses` - Create expense entry
- `GET /api/bills` - Get all bills
- `POST /api/bills` - Create bill entry

### Tasks & Goals
- `GET /api/tasks` - Get all tasks
- `POST /api/tasks` - Create task
- `GET /api/goals` - Get all goals
- `POST /api/goals` - Create goal

### Notes & Diary
- `GET /api/notes` - Get all notes
- `POST /api/notes` - Create note
- `PUT /api/notes/:id` - Update note
- `DELETE /api/notes/:id` - Delete note

### Analytics
- `GET /api/analytics/daily-pnl` - Get daily P&L data
- `GET /api/analytics/monthly-stats` - Get monthly statistics

### Health Check
- `GET /api/health` - Application health status

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/database
PGHOST=localhost
PGPORT=5432
PGUSER=finance_user
PGPASSWORD=your_password
PGDATABASE=personal_finance_db

# Application
NODE_ENV=production
PORT=5000
SESSION_SECRET=your_session_secret

# Optional integrations
NOTION_INTEGRATION_SECRET=your_notion_secret
NOTION_PAGE_URL=your_notion_page_url
```

## Development Scripts

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run check        # TypeScript type checking
npm run db:push      # Push database schema
```

## Project Structure

```
personal-finance-tracker/
├── client/                 # Frontend React application
│   ├── src/
│   │   ├── components/     # Reusable UI components
│   │   ├── pages/          # Page components
│   │   ├── hooks/          # Custom React hooks
│   │   └── lib/            # Utility functions
├── server/                 # Backend Express application
│   ├── index.ts           # Main server file
│   ├── routes.ts          # API routes
│   ├── storage.ts         # Database operations
│   └── auth-routes.ts     # Authentication routes
├── shared/                 # Shared types and schemas
│   └── schema.ts          # Database schema
├── dist/                   # Built application
├── deploy-production.sh   # One-click production deployment
└── manage.sh              # Management script (created after deployment)
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and type checking
5. Submit a pull request

## Security Features

- Session-based authentication
- CSRF protection
- SQL injection prevention (Drizzle ORM)
- Input validation with Zod
- Security headers (Helmet.js)
- Rate limiting on authentication endpoints

## Browser Support

- Chrome/Chromium 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:
1. Check the [DEPLOYMENT.md](DEPLOYMENT.md) guide
2. Review the troubleshooting section
3. Check application logs: `./manage.sh logs`
4. Verify deployment: `./verify-deployment.sh`

## Roadmap

- [ ] Mobile app (React Native)
- [ ] Advanced analytics and reporting
- [ ] Expense categorization with AI
- [ ] Integration with banking APIs
- [ ] Multi-currency support
- [ ] Team collaboration features
- [ ] Advanced budgeting tools
- [ ] Investment tracking
- [ ] Receipt scanning with OCR
- [ ] Automated bill payment reminders