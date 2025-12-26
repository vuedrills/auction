package config

import (
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	Port           string
	GinMode        string
	DatabaseURL    string
	JWTSecret      string
	JWTExpiryHours int
	UploadDir      string
	MaxUploadSize  int64

	// Supabase
	SupabaseProjectID  string
	SupabaseURL        string
	SupabaseAnonKey    string
	SupabaseServiceKey string
	SupabaseBucket     string

	// Email (Resend)
	ResendAPIKey string
	FromEmail    string
	FromName     string

	// Firebase (FCM)
	FirebaseServiceAccountPath string

	// App
	PublicURL string

	// Feature Flags
	EnablePhoneAuth bool // Set to true to enable Firebase SMS phone authentication
}

func Load() (*Config, error) {
	godotenv.Load()

	jwtExpiry, _ := strconv.Atoi(getEnv("JWT_EXPIRY_HOURS", "24"))
	maxUpload, _ := strconv.ParseInt(getEnv("MAX_UPLOAD_SIZE", "10485760"), 10, 64)

	return &Config{
		Port:               getEnv("PORT", "8080"),
		GinMode:            getEnv("GIN_MODE", "debug"),
		DatabaseURL:        getEnv("DATABASE_URL", ""),
		JWTSecret:          getEnv("JWT_SECRET", "change-me-in-production"),
		JWTExpiryHours:     jwtExpiry,
		UploadDir:          getEnv("UPLOAD_DIR", "./uploads"),
		MaxUploadSize:      maxUpload,
		SupabaseProjectID:  getEnv("SUPABASE_PROJECT_ID", ""),
		SupabaseURL:        getEnv("SUPABASE_URL", ""),
		SupabaseAnonKey:    getEnv("SUPABASE_ANON_KEY", ""),
		SupabaseServiceKey: getEnv("SUPABASE_SERVICE_KEY", ""),
		SupabaseBucket:     getEnv("SUPABASE_BUCKET", "auctionimages"),
		// Email
		ResendAPIKey: getEnv("RESEND_API_KEY", ""),
		FromEmail:    getEnv("FROM_EMAIL", "noreply@trabab.com"),
		FromName:     getEnv("FROM_NAME", "Trabab"),
		// Firebase
		FirebaseServiceAccountPath: getEnv("FIREBASE_SERVICE_ACCOUNT_PATH", "./servicekey.json"),
		// App
		PublicURL: getEnv("PUBLIC_URL", "http://localhost:8080"),

		// Feature Flags
		EnablePhoneAuth: getEnvBool("ENABLE_PHONE_AUTH", false), // Disabled by default (Firebase SMS is paid)
	}, nil
}

func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func getEnvBool(key string, defaultValue bool) bool {
	if value, exists := os.LookupEnv(key); exists {
		boolVal, err := strconv.ParseBool(value)
		if err == nil {
			return boolVal
		}
	}
	return defaultValue
}
