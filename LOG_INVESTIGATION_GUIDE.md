# Log Investigation Guide for Production Errors

## Quick Start (TL;DR)

**Fastest Method: Use Sentry**
1. Log into Sentry dashboard
2. Filter: `environment:production` + search `enrollment` or `CSRF`
3. Find the error with Request ID
4. Use Request ID to search logs: `grep "REQUEST_ID" /home/deployer/apps/mmss-mysql/current/log/puma.error.log`

**Quick Log Commands:**
```bash
# Most recent enrollment errors
grep -i "enrollment" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | grep -E "(error|exception|csrf|422)" | tail -20

# CSRF errors today
grep "$(date +%Y-%m-%d)" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | grep -i "csrf\|InvalidAuthenticityToken" | tail -20

# Watch logs in real-time
tail -f /home/deployer/apps/mmss-mysql/current/log/puma.error.log | grep -i "error\|csrf\|enrollment"
```

## Error Overview
The error "The change you wanted was rejected" is a Rails 422 error, typically caused by:
- CSRF token mismatch/expiration
- Session timeout
- Cookie issues (especially with secure cookies in production)

## Log Locations on Ubuntu Server

Based on your deployment configuration, logs are located at:

### Rails Application Logs
```bash
# Main production log (if not logging to STDOUT)
/home/deployer/apps/mmss-mysql/current/log/production.log

# If RAILS_LOG_TO_STDOUT is set, logs are in Puma logs (see below)
```

### Puma Application Server Logs
```bash
# Error log (most important for this investigation)
/home/deployer/apps/mmss-mysql/current/log/puma.error.log

# Access log
/home/deployer/apps/mmss-mysql/current/log/puma.access.log
```

### Nginx Web Server Logs
```bash
# Access log
/home/deployer/apps/mmss-mysql/current/log/nginx.access.log

# Error log
/home/deployer/apps/mmss-mysql/current/log/nginx.error.log
```

### System Logs (if using systemd)
```bash
# Puma service logs
sudo journalctl -u puma -f

# Or if using a different service name
sudo journalctl -u mmss-mysql-puma -f
```

## Commands to Scan Logs

### 1. Search for CSRF/422 Errors in Rails/Puma Logs

```bash
# Search for CSRF token errors
grep -i "csrf\|422\|rejected\|forgery" /home/deployer/apps/mmss-mysql/current/log/production.log | tail -50

# Search in Puma error log
grep -i "csrf\|422\|rejected\|forgery" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | tail -50

# Search for enrollment-related errors
grep -i "enrollment" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | grep -i "error\|exception\|csrf" | tail -50
```

### 2. Search by Request ID (if you have it from Sentry)

```bash
# If you have a request_id from Sentry, search for it
grep "REQUEST_ID_HERE" /home/deployer/apps/mmss-mysql/current/log/puma.error.log

# Or search in production log
grep "REQUEST_ID_HERE" /home/deployer/apps/mmss-mysql/current/log/production.log
```

### 3. Search by Time Range

```bash
# Find errors from today
grep "$(date +%Y-%m-%d)" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | grep -i "error\|exception"

# Find errors from a specific date (replace YYYY-MM-DD)
grep "YYYY-MM-DD" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | grep -i "error\|exception"

# Find errors in the last hour
grep "$(date -d '1 hour ago' +%Y-%m-%d)" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | tail -100
```

### 4. Search Nginx Logs for Enrollment Endpoint

```bash
# Find enrollment-related requests
grep "/enrollments" /home/deployer/apps/mmss-mysql/current/log/nginx.access.log | tail -50

# Find 422 status codes in Nginx
grep " 422 " /home/deployer/apps/mmss-mysql/current/log/nginx.access.log | tail -50

# Find errors related to enrollments
grep "/enrollments" /home/deployer/apps/mmss-mysql/current/log/nginx.error.log | tail -50
```

### 5. Real-time Log Monitoring

```bash
# Watch Puma error log in real-time
tail -f /home/deployer/apps/mmss-mysql/current/log/puma.error.log

# Watch with filtering for errors only
tail -f /home/deployer/apps/mmss-mysql/current/log/puma.error.log | grep -i "error\|exception\|csrf"

# Watch production log
tail -f /home/deployer/apps/mmss-mysql/current/log/production.log
```

### 6. Comprehensive Error Search

```bash
# Search for all ActionController::InvalidAuthenticityToken errors
grep "ActionController::InvalidAuthenticityToken" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | tail -50

# Search for Can't verify CSRF token authenticity
grep "Can't verify CSRF token authenticity" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | tail -50

# Search for enrollment controller errors
grep "EnrollmentsController" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | tail -50
```

## Using Sentry to Find the Error (RECOMMENDED)

Since you have Sentry configured, this is often the **easiest and fastest way** to find the error:

### Step 1: Access Sentry Dashboard
1. Log into your Sentry dashboard
2. Select your project

### Step 2: Filter for the Error
Use these filters in Sentry:
- **Environment**: `production`
- **Time Range**: When the applicant reported the error
- **Search Query**: `enrollment` OR `422` OR `CSRF` OR `InvalidAuthenticityToken`
- **Status**: `Unresolved` or `All`

### Step 3: Look for These Error Types
The error will likely appear as:
- **Error Type**: `ActionController::InvalidAuthenticityToken`
- **Error Message**: "Can't verify CSRF token authenticity" or "The change you wanted was rejected"
- **URL Path**: Contains `/enrollments` (e.g., `/enrollments` or `/enrollments/123`)
- **HTTP Status**: `422`

### Step 4: Review Error Details in Sentry
Click on the error to see:
- **Exact Timestamp**: When it occurred
- **Request ID**: Unique identifier (format: `[request_id:xxxx-xxxx-xxxx]`)
- **User Information**: 
  - User ID (if `Current.user` was set)
  - Email address (if available)
- **Full Stack Trace**: Shows where the error occurred
- **Request Parameters**: What data was being submitted
- **Headers**: Including cookies, user-agent, referer
- **Breadcrumbs**: Timeline of events leading to the error
- **Browser/Device Info**: User's browser, OS, device

### Step 5: Use Request ID to Find Log Entry
Once you have the Request ID from Sentry, search for it in your logs:

```bash
# Search in Puma error log
grep "REQUEST_ID_FROM_SENTRY" /home/deployer/apps/mmss-mysql/current/log/puma.error.log

# Search in production log
grep "REQUEST_ID_FROM_SENTRY" /home/deployer/apps/mmss-mysql/current/log/production.log

# Search in Nginx access log to see the full request
grep "REQUEST_ID_FROM_SENTRY" /home/deployer/apps/mmss-mysql/current/log/nginx.access.log
```

### Step 6: Analyze the Error Context
In Sentry, check:
- **Breadcrumbs**: Look for session-related events, cookie issues
- **User Context**: Verify if the user was properly authenticated
- **Request Headers**: Check if cookies were sent (especially `mmss_security_session`)
- **Previous Errors**: Check if this user had similar errors before
- **Affected Users**: See if this is affecting multiple users or just one

### Sentry Query Examples
In Sentry's search, you can use:
```
environment:production message:"CSRF" OR message:"InvalidAuthenticityToken"
environment:production url:"/enrollments"
environment:production status:422
```

## Common CSRF Error Patterns to Look For

```bash
# Pattern 1: Invalid authenticity token
grep "InvalidAuthenticityToken\|Can't verify CSRF" /home/deployer/apps/mmss-mysql/current/log/puma.error.log

# Pattern 2: Session issues
grep "session\|cookie" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | grep -i "error\|expired\|invalid"

# Pattern 3: 422 status codes
grep " 422 " /home/deployer/apps/mmss-mysql/current/log/nginx.access.log
```

## Quick One-Liner to Find Recent Enrollment Errors

```bash
# Find recent enrollment-related errors
grep -i "enrollment" /home/deployer/apps/mmss-mysql/current/log/puma.error.log | grep -E "(error|exception|csrf|422|rejected)" | tail -20
```

## Understanding the Log Output

When you find the error, look for:
- **Timestamp**: When it occurred
- **Request ID**: Unique identifier for the request
- **User ID/Email**: Who experienced it (if logged)
- **IP Address**: Where the request came from
- **User-Agent**: Browser/device information
- **Stack Trace**: Full error details
- **Request Parameters**: What data was being submitted

## Next Steps After Finding the Error

1. **Check if it's a one-time occurrence** or a pattern
2. **Review the user's session** - was it expired?
3. **Check cookie settings** - secure cookies in production
4. **Review the enrollment form** - ensure CSRF token is included
5. **Check for JavaScript errors** that might prevent token submission

## Additional Debugging

If you need more context, you can temporarily increase log verbosity:

```bash
# Check current log level (should be :info in production)
grep "log_level" /home/deployer/apps/mmss-mysql/current/config/environments/production.rb
```

Note: The log level is set to `:info` in production, which should capture CSRF errors.
