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
      # return { scope: 'bot,'\
      #                'chat:write:bot,'\
      #                'commands,'\
      #                'team:read,'\
      #                'users:read,'\
      #                'channels:history,'\
      #                'channels:read,'\
      #                'im:history,'\
      #                'im:read'
      #       }
      # Scopes and why needed:
      #    bot: - to be able to get the taskbot's slack user id to use to send
      #           taskbot msgs to the taskbot channel.
      #    users:read - to be able to use the users.list api method to verify
      #                 assigned names.
      #    chat:write:bot - to be able to use the chat.delete and
      #                 chat.postMessage api methods to clear taskbot msgs and
      #                 to post a new one.
      #    im:read - to be to use the api method im.list to get a list of
      #              direct message channels to build a members lookup hash.
      #    im:history - to be able to read the taskbot messages to get the msg
      #                 id so that it can be deleted.
      #    channels:read - to be able to use the api method channels.list
      #    commands - to allow teams to install the /do slash command.
      # API methods used:
      # 1) in models/concerns.channel_extensions.rb:
      #      def slack_dm_channels_from_rtm_data
      #    Slack::Web::Client.web_client.im_list['ims']
      #    uses token from team.api_token which is the miaDo api token from the
      #      member installing miaDo. (auth_hash[:auth]['credentials']['token'])
      # 2) in models/concerns.member_extensions.rb:
      #      def slack_members_from_rtm_data
      #    Slack::Web::Client.web_client.im_list['members']
      #    uses token from team.api_token which is the miaDo api token from the
      #      member installing miaDo. (auth_hash[:auth]['credentials']['token'])
      return { scope: 'bot,'\
                      'chat:write:bot,'\
                      'commands,'\
                      'users:read,'\
                      'channels:read,'\
                      'im:read,'\
                      'im:history'\
             }
      # ',users:read'\
      # ',im:read'\
      # ',im:history'\
      # ',chat:write:bot'\
      # ',channels:read'\
      # return { scope: ' commands'\
      #                ',bot'\
      #       }
    end
    return { scope: 'identity.basic' } if query == 'state=sign_in'
    {}
  end
end
