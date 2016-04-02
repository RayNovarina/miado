# lib/omniauth_github_setup.rb
class OmniauthGithubSetup
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

  # per: https://developer.github.com/v3/oauth/#scopes
  # (no scope)	Grants read-only access to public information (includes public
  #             user profile info, public repository info, and gists)
  # user:email	Grants read access to a user's email addresses.
  def customize_options
    return {} if (query = @env['QUERY_STRING']).nil?
    return { scope: 'user:email' } if query == 'state=sign_up'
    return {} if query == 'state=sign_in'
    {}
  end
end
