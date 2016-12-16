# Note: we are using SendGrid, hosted by our heroku app.
# Troubleshooting ActionMailer failures:
#   Adding config.raise_delivery_errors = true to your config/environments/development.rb file will tell
#   ActionMailer to raise informative errors if it fails. This can be very helpful for debugging.
# if Rails.env.development? || Rails.env.production?
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    address:        'smtp.sendgrid.net',
    port:           '2525',
    authentication: :plain,
    user_name:      ENV['SENDGRID_USERNAME'],
    password:       ENV['SENDGRID_PASSWORD'],
    domain:         'heroku.com',
    enable_starttls_auto: true
  }
# end
