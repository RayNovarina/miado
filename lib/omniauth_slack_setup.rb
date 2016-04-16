# lib/omniauth_slack_setup.rb
# included by /initializers/devise.rb at 'config.omniauth :slack'
class OmniauthSlackSetup
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

  def customize_options
    if (query = @env['QUERY_STRING']).nil?
      return {}
    end
    if query == 'state=sign_up'
      # return { scope: 'incoming-webhook,commands,'\
      #       'channels:write,channels:read,chat:write:user,'\
      #       'files:write:user,files:read,team:read,users:read' }
      # return { scope: 'bot,commands,'\
      #                'channels:history,channels:read,'\
      #                'im:history,im:read,'\
      #                'pins:read,pins:write,'\
      #                'chat:write:bot,'\
      #                'files:write:user,files:read,'\
      #                'search:read,'\
      #                'team:read,'\
      #                'users:read' }
      return { scope: 'commands,'\
                      'team:read,'\
                      'users:read' }
    end
    return { scope: 'identify' } if query == 'state=sign_in'
    {}
  end
end
