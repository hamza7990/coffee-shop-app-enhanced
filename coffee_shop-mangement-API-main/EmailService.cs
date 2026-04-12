using System.Net;
using System.Net.Mail;

namespace CoffeeShopAPI.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendPasswordResetEmailAsync(string email, string resetToken, string userName)
    {
        var smtpHost = _config["Email:SmtpHost"] ?? "smtp.gmail.com";
        var smtpPort = int.Parse(_config["Email:SmtpPort"] ?? "587");
        var smtpUser = _config["Email:Username"] ?? "";
        var smtpPass = _config["Email:Password"] ?? "";
        var fromEmail = _config["Email:From"] ?? "noreply@brewhaus.com";
        var fromName = _config["Email:FromName"] ?? "Brewhaus Coffee";
        var appUrl = _config["Email:AppUrl"] ?? "http://localhost:5000";

        try
        {
            var resetUrl = $"{appUrl}/reset-password?token={resetToken}";

            var subject = "Reset Your Password - Brewhaus Coffee";
            var body = $@"
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9; }}
        .header {{ background: #6B4226; color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }}
        .content {{ background: white; padding: 30px; border-radius: 0 0 8px 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        .button {{ display: inline-block; background: #6B4226; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin: 20px 0; }}
        .footer {{ text-align: center; margin-top: 30px; color: #666; font-size: 12px; }}
        .warning {{ background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>Password Reset Request</h1>
        </div>
        <div class='content'>
            <p>Hi <strong>{userName}</strong>,</p>
            <p>We received a request to reset your password for your Brewhaus Coffee Shop account.</p>
            
            <div style='text-align: center;'>
                <a href='{resetUrl}' class='button'>Reset My Password</a>
            </div>
            
            <div class='warning'>
                <strong>⚠️ Security Notice:</strong> This link will expire in 1 hour and can only be used once.
            </div>
            
            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p style='word-break: break-all; background: #f5f5f5; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 12px;'>{resetUrl}</p>
            
            <p>If you didn't request this password reset, you can safely ignore this email.</p>
        </div>
        <div class='footer'>
            <p>Brewhaus Coffee Shop Management System</p>
            <p>© 2024 All rights reserved.</p>
        </div>
    </div>
</body>
</html>";

            var message = new MailMessage
            {
                From = new MailAddress(fromEmail, fromName),
                Subject = subject,
                Body = body,
                IsBodyHtml = true
            };
            message.To.Add(email);

            using var client = new SmtpClient(smtpHost, smtpPort)
            {
                EnableSsl = true,
                Credentials = new NetworkCredential(smtpUser, smtpPass)
            };

            await client.SendMailAsync(message);
            _logger.LogInformation("Password reset email sent to {Email}", email);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send password reset email to {Email}", email);
            // In production, you might want to throw or handle this differently
        }
    }
}
