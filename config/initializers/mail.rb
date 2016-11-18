#
#================= Production using Mailgun ===================
# For Mailgun email service. Bloc.io ref: https://www.bloc.io/resources/mailgun-integration
ActionMailer::Base.smtp_settings = {
  port:              587,
  address:           'smtp.mailgun.org',
  user_name:         ENV['MAILGUN_SMTP_LOGIN'],
  password:          ENV['MAILGUN_SMTP_PASSWORD'],
  domain:            Rails.env == 'staging' ? 'https://qa.miado.net' : 'https://miado.net/',
  authentication:    :plain,
  content_type:      'text/html'
}
ActionMailer::Base.delivery_method = :smtp

# Makes debugging *way* easier.
ActionMailer::Base.raise_delivery_errors = true

# This interceptor just makes sure that local mail
# only emails you.
# http://edgeguides.rubyonrails.org/action_mailer_basics.html#intercepting-emails
class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.to = 'RNova94037@Gmail.com'
    message.cc = nil
    message.bcc = nil
  end
end

# Locally, outgoing mail will be 'intercepted' by the
# above DevelopmentMailInterceptor before going out
# Note to verify via rails console:
#   $ ActionMailer::Base::Mail.class_variable_get(:@@delivery_interceptors)
if Rails.env.development?
  ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor)
end
#===============================================================================

#================= Development using Mailcatcher ===============================
# Locally, outgoing mail will be 'intercepted' by the
# above DevelopmentMailInterceptor before going out
# Note: using Mailcatcher gem at: http://mailcatcher.me/
# if Rails.env.development?
#  config.action_mailer.delivery_method = :smtp
#  config.action_mailer.smtp_settings = { address: 'localhost', port: 1025 }
# end
