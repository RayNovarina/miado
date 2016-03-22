Rails.application.configure do
  # Settings specified here will take precedence over those in
  # config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all
  # assets, yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # ====== EMAIL ========
  # ??Enable email sending? this is the default?
  config.action_mailer.perform_deliveries = true
  #
  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to
  # raise delivery errors.
  config.action_mailer.raise_delivery_errors = false
  #
  # For ActionMailer to auto include :host when generating absolute urls.
  # Ref: 2.6 Generating URLs in Action Mailer Views at
  # http://guides.rubyonrails.org/action_mailer_basics.html
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  #
  # ------ email delivery method/smtp server:
  # Note: if .delivery_method not specified then? smtp msg goes to ActiveMailer
  # listener off of localhost:25??
  # 1) Email goes to the console.
  # config.action_mailer.delivery_method = nil
  #
  # 2) To send mail from dev machine to smtp server at Gmail account to send.
  # config.action_mailer.delivery_method = :smtp
  # config.action_mailer.smtp_settings = {
  #  address: 'smtp.gmail.com',
  #  port: '587',
  #  domain: 'gmail.com',
  #  authentication: 'plain',
  #  enable_starttls_auto: true,
  #  user_name: 'xxxxx@Gmail.com',
  #  password: 'xxxx'
  # }
  #
  # 3) To send from local dev machine to via Mailcather gem:
  # gem install mailcatcher
  # bundle install
  # Add/change the following options and stop/restart the server.
  # In terminal window/shell run mailcatcher via: > mailcatcher
  # It will intercept email sent to port 25? and post/redirect it? to port
  # 1025?. In a browser run the mailcatcher web app at: http://127.0.0.1:1080
  # config.action_mailer.delivery_method = :smtp
  # config.action_mailer.smtp_settings = { address: 'localhost', port: 1025 }
  #
  # 4) To send from local dev to console via ActionMailer::MailInterceptor
  # This is done via the config/initializers/mail.rb file set up for Mailgun.
end
