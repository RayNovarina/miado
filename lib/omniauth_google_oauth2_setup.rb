# lib/omniauth_google_oauth2_setup.rb
class OmniauthGoogleOauth2Setup
  # OmniAuth expects the class passed to setup to respond to the #call method.
  # env - Rack environment
  def self.call(env)
    new(env).setup
  end

  # Assign variables and create a request object for use later.
  # env - Rack environment
  def initialize(env)
    @env = env
    @request = ActionDispatch::Request.new(env)
  end

  # private

  # The main purpose of this method is to modify the oauth auth url options.
  def setup
    @env['omniauth.strategy'].options.merge!(customize_options)
  end

  # per: https://github.com/zquestz/omniauth-google-oauth2
  # (no scope)	The email and profile scopes are used by default.
  def customize_options
    # return {} if (query = @env['QUERY_STRING']).nil?
    # return { scope: 'email, profile, plus.me' } if query == 'state=sign_up'
    # return {} if query == 'state=sign_in'
    {}
  end
end
