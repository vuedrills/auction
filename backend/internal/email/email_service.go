package email

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"net/http"

	"github.com/airmass/backend/internal/config"
)

// EmailService handles sending emails via Resend
type EmailService struct {
	apiKey    string
	fromEmail string
	fromName  string
	baseURL   string
}

// NewEmailService creates a new email service
func NewEmailService(cfg *config.Config) *EmailService {
	return &EmailService{
		apiKey:    cfg.ResendAPIKey,
		fromEmail: cfg.FromEmail,
		fromName:  cfg.FromName,
		baseURL:   cfg.PublicURL,
	}
}

// SendEmail sends an email via Resend API
func (s *EmailService) SendEmail(to, subject, htmlContent string) error {
	if s.apiKey == "" {
		return fmt.Errorf("Resend API key not configured")
	}

	payload := map[string]interface{}{
		"from":    fmt.Sprintf("%s <%s>", s.fromName, s.fromEmail),
		"to":      []string{to},
		"subject": subject,
		"html":    htmlContent,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	req, err := http.NewRequest("POST", "https://api.resend.com/emails", bytes.NewBuffer(jsonData))
	if err != nil {
		return err
	}

	req.Header.Set("Authorization", "Bearer "+s.apiKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("Resend API error: status %d", resp.StatusCode)
	}

	return nil
}

// SendPasswordReset sends a password reset email
func (s *EmailService) SendPasswordReset(to, resetToken, userName string) error {
	resetURL := fmt.Sprintf("%s/reset-password?token=%s", s.baseURL, resetToken)

	html := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .logo { text-align: center; margin-bottom: 30px; }
        .logo h1 { color: #EE456B; margin: 0; font-size: 32px; }
        h2 { color: #333; margin-top: 0; }
        p { color: #666; line-height: 1.6; }
        .button { display: inline-block; background: #EE456B; color: white; padding: 14px 32px; text-decoration: none; border-radius: 12px; font-weight: bold; margin: 20px 0; }
        .button:hover { background: #d93d5f; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #999; font-size: 12px; }
        .code { background: #f0f0f0; padding: 15px 20px; border-radius: 8px; font-family: monospace; font-size: 24px; text-align: center; letter-spacing: 4px; color: #333; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo"><h1>🔨 Trabab</h1></div>
        <h2>Reset Your Password</h2>
        <p>Hi %s,</p>
        <p>We received a request to reset your password. Click the button below to create a new password:</p>
        <p style="text-align: center;">
            <a href="%s" class="button">Reset Password</a>
        </p>
        <p>Or copy this link: <br><small>%s</small></p>
        <p>This link will expire in 1 hour for security reasons.</p>
        <p>If you didn't request this, you can safely ignore this email.</p>
        <div class="footer">
            <p>© 2024 Trabab. Your Town. Your Auctions.</p>
        </div>
    </div>
</body>
</html>
`, userName, resetURL, resetURL)

	return s.SendEmail(to, "Reset Your Password - Trabab", html)
}

// SendEmailVerification sends an email verification code
func (s *EmailService) SendEmailVerification(to, code, userName string) error {
	html := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .logo { text-align: center; margin-bottom: 30px; }
        .logo h1 { color: #EE456B; margin: 0; font-size: 32px; }
        h2 { color: #333; margin-top: 0; }
        p { color: #666; line-height: 1.6; }
        .code { background: linear-gradient(135deg, #EE456B 0%%, #FF8322 100%%); padding: 20px 30px; border-radius: 12px; font-family: monospace; font-size: 32px; text-align: center; letter-spacing: 8px; color: white; font-weight: bold; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #999; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo"><h1>🔨 Trabab</h1></div>
        <h2>Verify Your Email</h2>
        <p>Hi %s,</p>
        <p>Welcome to Trabab! Use the code below to verify your email address:</p>
        <div class="code">%s</div>
        <p>This code will expire in 15 minutes.</p>
        <p>If you didn't create a Trabab account, you can safely ignore this email.</p>
        <div class="footer">
            <p>© 2024 Trabab. Your Town. Your Auctions.</p>
        </div>
    </div>
</body>
</html>
`, userName, code)

	return s.SendEmail(to, "Verify Your Email - Trabab", html)
}

// SendAuctionWon sends a notification when user wins an auction
func (s *EmailService) SendAuctionWon(to, userName, auctionTitle string, finalPrice float64, sellerName string) error {
	html := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .logo { text-align: center; margin-bottom: 30px; }
        .logo h1 { color: #EE456B; margin: 0; font-size: 32px; }
        .trophy { font-size: 64px; text-align: center; margin: 20px 0; }
        h2 { color: #333; margin-top: 0; text-align: center; }
        p { color: #666; line-height: 1.6; }
        .highlight { background: linear-gradient(135deg, #22C55E 0%%, #16a34a 100%%); padding: 20px; border-radius: 12px; color: white; text-align: center; margin: 20px 0; }
        .highlight h3 { margin: 0 0 10px 0; font-size: 18px; opacity: 0.9; }
        .highlight .price { font-size: 36px; font-weight: bold; margin: 0; }
        .button { display: inline-block; background: #EE456B; color: white; padding: 14px 32px; text-decoration: none; border-radius: 12px; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #999; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo"><h1>🔨 Trabab</h1></div>
        <div class="trophy">🏆</div>
        <h2>Congratulations, You Won!</h2>
        <p>Hi %s,</p>
        <p>Great news! You've won the auction for <strong>%s</strong>!</p>
        <div class="highlight">
            <h3>Final Price</h3>
            <p class="price">$%.2f</p>
        </div>
        <p>The seller <strong>%s</strong> has been notified. They will contact you to arrange payment and pickup/delivery.</p>
        <p style="text-align: center;">
            <a href="%s/messages" class="button">Contact Seller</a>
        </p>
        <div class="footer">
            <p>© 2024 Trabab. Your Town. Your Auctions.</p>
        </div>
    </div>
</body>
</html>
`, userName, auctionTitle, finalPrice, sellerName, s.baseURL)

	return s.SendEmail(to, fmt.Sprintf("🏆 You Won: %s - Trabab", auctionTitle), html)
}

// SendOutbid sends a notification when user is outbid
func (s *EmailService) SendOutbid(to, userName, auctionTitle string, newPrice float64) error {
	html := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .logo { text-align: center; margin-bottom: 30px; }
        .logo h1 { color: #EE456B; margin: 0; font-size: 32px; }
        .alert { font-size: 48px; text-align: center; margin: 20px 0; }
        h2 { color: #333; margin-top: 0; }
        p { color: #666; line-height: 1.6; }
        .price-box { background: #FEF3C7; border: 1px solid #F59E0B; padding: 15px 20px; border-radius: 12px; text-align: center; margin: 20px 0; }
        .price-box .label { color: #92400E; font-size: 14px; margin: 0; }
        .price-box .price { color: #92400E; font-size: 28px; font-weight: bold; margin: 5px 0 0 0; }
        .button { display: inline-block; background: #EE456B; color: white; padding: 14px 32px; text-decoration: none; border-radius: 12px; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #999; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo"><h1>🔨 Trabab</h1></div>
        <div class="alert">⚡</div>
        <h2>You've Been Outbid!</h2>
        <p>Hi %s,</p>
        <p>Someone placed a higher bid on <strong>%s</strong>.</p>
        <div class="price-box">
            <p class="label">Current High Bid</p>
            <p class="price">$%.2f</p>
        </div>
        <p>Don't let it slip away! Place a new bid now to stay in the running.</p>
        <p style="text-align: center;">
            <a href="%s/auctions" class="button">Bid Again</a>
        </p>
        <div class="footer">
            <p>© 2024 Trabab. Your Town. Your Auctions.</p>
        </div>
    </div>
</body>
</html>
`, userName, auctionTitle, newPrice, s.baseURL)

	return s.SendEmail(to, fmt.Sprintf("⚡ Outbid: %s - Trabab", auctionTitle), html)
}

// EmailTemplate represents an email template
type EmailTemplate struct {
	Name    string
	Subject string
	HTML    string
}

// RenderTemplate renders an email template with data
func RenderTemplate(tmpl *template.Template, data interface{}) (string, error) {
	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, data); err != nil {
		return "", err
	}
	return buf.String(), nil
}
