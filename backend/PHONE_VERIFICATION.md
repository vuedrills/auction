# Phone Verification System

## Current Status: **READY BUT DISABLED**

The phone verification badge infrastructure is fully implemented and working. The authentication endpoints are disabled by default because Firebase SMS requires a paid plan.

## What's Working Now ✅

- **Phone Verified Badge**: Fully functional badge system
- **Database Structure**: `phone_verified`, `phone_verified_at` fields in users table
- **Badge Auto-Award**: Badge worker automatically awards badge to users with `phone_verified = true`
- **Feature Toggle**: `ENABLE_PHONE_AUTH` environment variable

## How The Badge Works

The badge is awarded automatically when a user's `phone_verified` flag is set to `true` in the database. The badge worker runs every 5 minutes and checks for users who:
1. Have `phone_verified = TRUE`
2. Don't already have the "Phone Verified" badge

## Enabling Phone Authentication (Future)

When you're ready to enable Firebase SMS phone authentication:

### 1. Set up Firebase Phone Auth
- Enable Phone Authentication in Firebase Console
- Configure your billing (required for SMS in production)
- Ensure `firebase-service-account.json` is in place

### 2. Enable the Feature
Add to `.env`:
```bash
ENABLE_PHONE_AUTH=true
```

### 3. Uncomment Routes
In `backend/internal/router/router.go`, uncomment these lines:
```go
auth.POST("/phone/verify", middleware.Auth(jwtService), authHandler.VerifyPhone)
auth.POST("/phone/signin", authHandler.PhoneSignIn)
auth.POST("/phone/register", authHandler.PhoneRegister)
```

### 4. Implement Phone Auth Handlers
You'll need to create the phone auth handlers in `auth_handler.go` with:
- `VerifyPhone()` - Mark phone as verified
- `PhoneSignIn()` - Sign in with phone number
- `PhoneRegister()` - Register with phone number

## Manual Phone Verification (Admin Dashboard)

For now, you can manually verify phone numbers via admin dashboard by updating:
```sql
UPDATE users 
SET phone_verified = true, phone_verified_at = NOW() 
WHERE id = 'user-id-here';
```

The badge will be auto-awarded within 5 minutes.

## Badge Details

- **Name**: `phone_verified`
- **Display Name**: Phone Verified
- **Description**: Verified phone number
- **Icon**: phone
- **Category**: verification
- **Priority**: 95 (high priority verification badge)

## Files Modified

- `backend/internal/database/migrations/020_phone_verification.sql` - Database schema
- `backend/internal/models/user.go` - User model with phone fields
- `backend/internal/worker/badge_worker.go` - Badge auto-award logic
- `backend/internal/config/config.go` - Feature flag configuration
- `backend/internal/router/router.go` - Routes (commented out)
