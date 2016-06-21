require 'slack-ruby-client'
# per: https://richonrails.com/articles/rails-4-code-concerns-in-active-record-models
module ChannelExtensions
  extend ActiveSupport::Concern
  #
  included do
    # see user_extensions.rb for usage.
  end
  #
  #======== CLASS METHODS, i.e. User.authenticate()
  #
  # The code contained within this block will be added to the Class itself.
  # For example, the code above adds an authenticate function to the User class.
  # This allows you to do User.authenticate(email, password) instead of
  # User.find_by_email(email).authenticate(password).
  module ClassMethods
    attr_accessor :view

    # install_channel = Channel.update_from_or_create_from(source: :omniauth_callback, request: request)
    # @view.channel   = Channel.find_or_create_from(source: :slack, view: @view, url_params: params)
    def find_or_create_from(options)
      return find_or_create_from_slack(options) if options[:source] == :slack
    end

    def update_from_or_create_from(options)
      return update_from_or_create_from_omniauth_callback(options) if options[:source] == :omniauth_callback
    end

    def find_from(options)
      return find_from_slack(options) if options[:source] == :slack
      return find_from_omniauth_callback(options) if options[:source] == :omniauth_callback
    end

    def create_from(options)
      return create_from_slack(options) if options[:source] == :slack
      return create_from_omniauth_callback(options) if options[:source] == :omniauth_callback
    end

    private

    def find_or_create_from_slack(options)
      if (channel = find_from_slack(options)).nil?
        # Case: This channel has not been accessed before.
        channel = create_from_slack(options)
      end
      channel
    end

    def update_from_or_create_from_omniauth_callback(options)
      # Case: We have not authenticated this oauth user before.
      return create_from_omniauth_callback(options) if (channel = find_from_omniauth_callback(options)).nil?
      # Case: We are reinstalling. Update auth info.
      update_channel_auth_info(channel, options)
      # Return channel with current auth callback info
      channel
    end

    def find_from_slack(options)
      @view ||= options[:view]
      Channel.where(slack_user_id: options[:slash_url_params]['user_id'],
                    slack_team_id: options[:slash_url_params]['team_id'],
                    slack_channel_id: options[:slash_url_params]['channel_id']).first
    end

    def find_from_omniauth_callback(options)
      @view ||= options[:view]
      Channel.where(slack_channel_name: 'installation',
                    slack_user_id: options[:request].env['omniauth.auth'].uid,
                    slack_team_id: options[:request].env['omniauth.auth'].info['team_id']).first
    end

=begin
  Form Params
  channel_id	C0VNKV7BK
  channel_name	general
  command	/do
  response_url	https://hooks.slack.com/commands/T0VN565N0/36163731489/YAHWUMXlBdviTE1rBILELuFK
  team_domain	shadowhtracteam
  team_id	T0VN565N0
  text	call GoDaddy @susan /fri
  token	3ZQVG7rk4p7EZZluk1gTH3aN
  user_id	U0VLZ5P51
  user_name	ray
=end
    def create_from_slack(options)
      @view ||= options[:view]
      # we create channel and copy members_hash from last active channel
      # for this team.
      other_member_channel =
        Channel.where(slack_team_id: options[:slash_url_params]['team_id']).first
      return nil if other_member_channel.nil?
      Channel.create!(
        slack_channel_name: options[:slash_url_params]['channel_name'],
        slack_channel_id: options[:slash_url_params]['channel_id'],
        slack_user_id: options[:slash_url_params]['user_id'],
        slack_team_id: options[:slash_url_params]['team_id'],
        slack_user_api_token: other_member_channel.slack_user_api_token,
        bot_api_token: other_member_channel.bot_api_token,
        bot_user_id: other_member_channel.bot_user_id,
        members_hash: other_member_channel.members_hash
      )
    end

    def create_from_omniauth_callback(options)
      auth = options[:request].env['omniauth.auth']
      channel = Channel.new(
        slack_channel_name: 'installation',
        slack_channel_id: '',
        slack_user_id: auth.uid,
        slack_team_id: auth.info['team_id']
      )
      update_channel_auth_info(channel, options)
      channel
    end

    def update_channel_auth_info(channel, options)
      auth = options[:request].env['omniauth.auth']
      members_hash = {}
      m_hash = {
        slack_user_name: auth.info['user'],
        slack_real_name: auth.info['user'],
        slack_user_id: auth.uid,
        slack_user_api_token: auth.credentials['token'],
        bot_user_id: auth.extra['bot_info']['bot_user_id'],
        bot_dm_channel_id: find_bot_dm_channel_id(
          bot_user_id: auth.extra['bot_info']['bot_user_id'],
          api_token: auth.credentials['token']),
        bot_msg_id: nil,
        bot_api_token: auth.extra['bot_info']['bot_access_token']
      }
      members_hash[m_hash[:slack_user_name]] = m_hash
      members_hash[m_hash[:slack_user_id]] = m_hash

      channel.slack_user_api_token = auth.credentials['token']
      channel.bot_api_token = auth.extra['bot_info']['bot_access_token']
      channel.bot_user_id = auth.extra['bot_info']['bot_user_id']
      channel.auth_json = auth
      channel.auth_params_json = options[:request].env['omniauth.params']
      channel.members_hash = members_hash
      channel.save!
    end

    def find_bot_dm_channel_id(options)
      slack_dm_channels = slack_dm_channels_from_rtm_data(
        rtm_api_client: make_web_client(options[:api_token]))
      slack_dm_channels.each do |im|
        next if im[:is_user_deleted]
        return im[:id] if im[:user] == options[:bot_user_id]
      end
      nil
    end

    def slack_dm_channels_from_rtm_data(options)
      # response is an array of hashes. Each has name and id of a team channel.
      options[:rtm_api_client].im_list['ims']
    end

    def make_web_client(api_token)
      # Slack.config.token = 'xxxxx'
      Slack.configure do |config|
        config.token = api_token
      end
      Slack::Web::Client.new
    end
    #
  end # module ClassMethods

  #
  #======== INSTANCE METHODS, i.e. User.find_by(1).create_password_token()
  #
  # Code not included in the ClassMethods block or the included block will be
  # included as instance methods.
  # see user_extensions.rb for usage.
end # module UserExtensions
