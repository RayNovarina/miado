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

    # Various methods to support Installations and Team and Members models.

    def installations(options = {})
      if options.key?(:slack_user_id)
        return Channel.where(slack_channel_name: 'installation')
                      .where(slack_team_id: options[:slack_team_id])
                      .where(slack_user_id: options[:slack_user_id])
                      .reorder('slack_team_id ASC')
      end
      if options.key?(:slack_team_id)
        return Channel.where(slack_channel_name: 'installation')
                      .where(slack_team_id: options[:slack_team_id])
                      .reorder('slack_team_id ASC')
      end
      Channel.where(slack_channel_name: 'installation')
             .reorder('slack_team_id ASC')
    end

    def teams
      Channel.where(slack_channel_name: 'installation')
             .select('DISTINCT ON(slack_team_id)*')
             .reorder('slack_team_id ASC')
    end

    def team_members(options = {})
      install_channels = [installations(options).first] if options.key?(:slack_team_id)
      install_channels = teams unless options.key?(:slack_team_id)
      members = []
      install_channels.each do |install_channel|
        install_channel.members_hash.each do |key, value|
          members << value if key.starts_with?('U')
        end
      end
      members
    end

    def team_channels(options = {})
      if options.key?(:slack_team_id)
        return Channel.where(slack_team_id: options[:slack_team_id])
                      .where.not(slack_channel_name: 'installation')
                      .reorder('slack_channel_name ASC')
      end
      Channel.where.not(slack_channel_name: 'installation')
             .reorder('slack_channel_name ASC')
    end

    def team_lists(options = {})
      if options.key?(:slack_team_id)
        []
      else
        []
      end
    end

    def shared_team_channels(options)
      channels = team_channels(options)
      shared_channels = []
      channels.each do |channel|
        shared_channels << channel unless channel.slack_channel_id.starts_with?('D')
      end
      shared_channels
    end

    def dm_team_channels(options)
      channels = team_channels(options)
      dm_channels = []
      channels.each do |channel|
        dm_channels << channel if channel.slack_channel_id.starts_with?('D')
      end
      dm_channels
    end

    def bot_team_channels(options)
      channels = dm_team_channels(options)
      bot_channels = []
      channels.each do |channel|
        bot_channels << channel unless channel.slack_user_id.starts_with?('U')
      end
      bot_channels
    end

    def last_activity(options = {})
      # if options.key?(:slack_user_id)
      #  return Channel.where(slack_team_id: options[:slack_team_id])
      #                .where(updated_by_slack_user_id: options[:slack_user_id])
      #                .reorder('updated_at ASC').last.updated_at
      # end
      if options.key?(:slack_team_id)
        last_active = Channel.where(slack_team_id: options[:slack_team_id])
                             .reorder('updated_at ASC').last
      end
      if options.key?(:user)
        last_active = Channel.all.reorder('updated_at ASC').last
      end
      return last_active.updated_at unless last_active.nil?
      nil
    end

    def bot_info(options)
      b_hash = { name: '*no bot*', id: nil, user_id: nil, access_token: nil }
      if options.key?(:installations)
        return b_hash if options[:installations].empty? || options[:installations][0].bot_user_id.nil?
        install_channel = options[:installations][options[:installations].length-1]
      elsif options.key?(:slack_team_id)
        install_channel = installations(options)
      end
      b_hash[:user_id] = install_channel.auth_json['extra']['bot_info']['bot_user_id']
      b_hash[:access_token] = install_channel.bot_api_token
      # bot_id = nil
      # install_channel.rtm_start_json['users'].each do |user|
      #  next unless user['id'] == bot_user_id
      #  bot_id = user['profile']['bot_id']
      #  break
      # end
      b_hash[:id] =
        install_channel.rtm_start_json['users']
        .map { |user| user['id'] == b_hash[:user_id] ? user['profile']['bot_id'] : nil }
        .compact[0]
      return b_hash if b_hash[:id].nil?
      # bot_name = nil
      # install_channel.rtm_start_json['bots'].each do |bot|
      #  next unless bot['id'] == bot_id
      #  bot_name = bot['name']
      #  break
      # end
      b_hash[:name] =
        install_channel.rtm_start_json['bots']
        .map { |bot| bot['id'] == b_hash[:id] ? bot['name'] : nil }
        .compact[0]
      b_hash
    end

    private

    def find_or_create_from_slack(options)
      if (channel = find_from_slack(options)).nil?
        # Case: This channel has not been accessed before.
        channel = create_from_slack(options)
      end
      channel
    end

    # Return install channel with current auth callback info
    def update_from_or_create_from_omniauth_callback(options)
      # Case: We have not authenticated this oauth user before.
      return create_from_omniauth_callback(options) if (install_channel = find_from_omniauth_callback(options)).nil?
      # Case: We are reinstalling. Update auth info.
      update_channel_auth_info(install_channel, options)
      # Update fields changed by reinstall for all team channels for this user.
      update_channel_reinstall_info(install_channel, options)
      install_channel
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
      members_hash, rtm_start_json = find_or_create_members_hash_from_omniauth_callback(options)
      channel.slack_user_api_token = auth.credentials['token']
      channel.bot_api_token = auth.extra['bot_info']['bot_access_token']
      channel.bot_user_id = auth.extra['bot_info']['bot_user_id']
      channel.auth_json = auth
      channel.auth_params_json = options[:request].env['omniauth.params']
      channel.members_hash = members_hash
      channel.rtm_start_json = rtm_start_json
      channel.save!
    end

    # Returns: nothing. Db is updated.
    # Update fields changed by reinstall for all team channels.
=begin
    {"dawndn"=>
    {"bot_msg_id"=>"1467131715.000005",
     "bot_user_id"=>"U1BAYPNAH",
     "bot_api_token"=>"xoxb-45372804357-1ERJ1TLnNqymm8G2DdGr9BmJ",
     "slack_user_id"=>"U02GW9E04",
     "slack_real_name"=>"Dawn  DeBruyn",
     "slack_user_name"=>"dawndn",
     "bot_dm_channel_id"=>"D1B9J8PCK",
     "slack_user_api_token"=>"xoxp-2574213018-2574320004-53530428656-3054888f5e"},
=end
    def update_channel_reinstall_info(install_channel, options)
      auth = options[:request].env['omniauth.auth']
      # First update reinstall info for the user.
      Channel.where(slack_user_id: auth.uid)
             .where(slack_team_id: auth.info['team_id'])
             .update_all(slack_user_api_token: install_channel.slack_user_api_token,
                         bot_api_token: install_channel.bot_api_token,
                         bot_user_id: install_channel.bot_user_id)
      # Next update reinstall info for all team members.
      Channel.where(slack_team_id: auth.info['team_id'])
             .update_all(members_hash: install_channel.members_hash)
    end

    # Returns: [members_hash, rtm_start]
    def find_or_create_members_hash_from_omniauth_callback(options)
      auth = options[:request].env['omniauth.auth']
      rtm_start = start_data_from_rtm_start(auth.extra['bot_info']['bot_access_token'])
      other_install_channel =
        Channel.where(slack_channel_name: 'installation',
                      slack_team_id: auth.info['team_id'])
               .where.not(slack_user_id: auth.uid).first
      return create_members_hash_from_rtm_start(auth: auth, rtm_start: rtm_start) if other_install_channel.nil?
      members_hash = other_install_channel.members_hash
      update_members_hash_for_reinstall_from_rtm_start(members_hash: members_hash, auth: auth,
                                         rtm_start: rtm_start)
      # update_members_hash_from_omniauth_callback(members_hash: members_hash,
      #                                           auth: auth)
    end

    # Member is reinstalling MiaDo. tokens need to be updated in the members_hash.
    # Returns: [members_hash, rtm_start]
    def update_members_hash_for_reinstall_from_rtm_start(options)
      auth = options[:auth]
      members_hash = options[:members_hash]
      rtm_start = options[:rtm_start]
      # Add installing member's info to existing team lookup hash.
      add_new_member_to_hash(
        members_hash: members_hash,
        rtm_start: rtm_start,
        name: auth.info['user'],
        real_name: auth.info['user'],
        id: auth.uid,
        api_token: auth.credentials['token'],
        bot_user_id: auth.extra['bot_info']['bot_user_id'],
        bot_api_token: auth.extra['bot_info']['bot_access_token']
      )
      [members_hash, rtm_start]
    end

    def add_new_member_to_hash(options)
      m_hash =
        { slack_user_name: options[:name],
          slack_real_name: options[:real_name],
          slack_user_id: options[:id],
          slack_user_api_token: options[:api_token],
          bot_user_id: options[:bot_user_id],
          bot_api_token: options[:bot_api_token],
          bot_dm_channel_id: nil,
          bot_msg_id: nil
        }
      unless (im = find_bot_dm_channel_from_rtm_start(
                     slack_user_id: options[:id],
                     rtm_start: options[:rtm_start])).nil?
        m_hash[:bot_dm_channel_id] = im['id']
        m_hash[:bot_msg_id] = nil if im['latest'].nil?
        m_hash[:bot_msg_id] = im['latest']['ts'] unless im['latest'].nil?
      end
      options[:members_hash][m_hash[:slack_user_name]] = m_hash
      options[:members_hash][m_hash[:slack_user_id]] = m_hash
    end

    # Returns: [members_hash, rtm_start]
    def create_members_hash_from_rtm_start(options)
      auth = options[:auth]
      members_hash = {}
      rtm_start = options[:rtm_start]
      slack_members = rtm_start['users']
      slack_members.each do |slack_member|
        next if slack_member['name'] == 'slackbot' || slack_member['deleted'] ||
                slack_member['is_bot']
        add_new_member_to_hash(
          members_hash: members_hash,
          rtm_start: rtm_start,
          name: slack_member['name'],
          real_name: slack_member['real_name'],
          id: slack_member['id'],
          api_token: slack_member['id'] == auth.uid ? auth.credentials['token'] : nil,
          bot_user_id: slack_member['id'] == auth.uid ? auth.extra['bot_info']['bot_user_id'] : nil,
          bot_api_token: slack_member['id'] == auth.uid ? auth.extra['bot_info']['bot_access_token'] : nil
        )
      end
      [members_hash, rtm_start]
    end

=begin
    {
                "id": "D18E3GH2P",
                "user": "U0VLZ5P51",
                "created": 1463082203,
                "is_im": true,
                "is_org_shared": false,
                "has_pins": false,
                "last_read": "0000000000.000000",
                "latest": {
                    "text": "`Current tasks list for @ray in all Team channels (Open)`",
                    "username": "MiaDo Taskbot",
                    "bot_id": "B1K3DLYNA",
                    "attachments": [
                        {
                            "text": "---- #general channel ----------",
                            "id": 1,
                            "mrkdwn_in": [
                                "text"
                            ],
                            "fallback": "NO FALLBACK DEFINED"
                        },
                        {
                            "text": "1) new general task1 for ray | *Assigned* to @ray.",
                            "id": 2,
                            "mrkdwn_in": [
                                "text"
                            ],
                            "fallback": "NO FALLBACK DEFINED"
                        }
                    ],
                    "type": "message",
                    "subtype": "bot_message",
                    "ts": "1466566560.000007"
                },
                "unread_count": 2,
                "unread_count_display": 2,
                "is_open": true
            },
=end
    def find_bot_dm_channel_from_rtm_start(options)
      slack_dm_channels = options[:rtm_start]['ims']
      slack_dm_channels.each do |im|
        next if im[:is_user_deleted]
        return im if im['user'] == options[:slack_user_id]
      end
      nil
    end

    # response is an array of hashes. Team, users, channels, dms.
    def start_data_from_rtm_start(api_token)
      slack_api('rtm.start', api_token)
    end

    def slack_api(method_name, api_token)
      uri = URI.parse('https://slack.com')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new("/api/#{method_name}?token=#{api_token}")
      response = http.request(request)
      JSON.parse(response.body)
    end

=begin
    def make_rtm_client(api_token)
      # Slack.config.token = 'xxxxx'
      Slack.configure do |config|
        config.token = api_token
      end
      Slack::RealTime::Client.new
    end

    def update_members_hash_from_omniauth_callback(options)
      auth = options[:auth]
      # Delete placeholder id if we made one up when processing a task assignment.
      options[:members_hash].delete('id.'.concat(auth.info['user']))
      i_hash =
        { slack_user_name: auth.info['user'],
          slack_real_name: auth.info['user'],
          slack_user_id: auth.uid,
          # slack_user_api_token: auth.credentials['token'],
          slack_user_api_token: auth.extra['bot_info']['bot_access_token'],
          bot_user_id: auth.extra['bot_info']['bot_user_id'],
          bot_dm_channel_id: find_bot_dm_channel_from_im_list(
            bot_user_id: auth.extra['bot_info']['bot_user_id'],
            api_token: auth.credentials['token']),
          bot_msg_id: nil,
          bot_api_token: auth.extra['bot_info']['bot_access_token']
        }
      options[:members_hash][i_hash[:slack_user_name]] = i_hash
      options[:members_hash][i_hash[:slack_user_id]] = i_hash
      [options[:members_hash], nil]
    end

    def find_bot_dm_channel_from_im_list(options)
      slack_dm_channels = slack_dm_channels_from_im_list(
        api_client: make_web_client(options[:api_token]))
      slack_dm_channels.each do |im|
        next if im[:is_user_deleted]
        return im[:id] if im[:user] == options[:bot_user_id]
      end
      nil
    end

    def slack_dm_channels_from_im_list(options)
      # response is an array of hashes. Each has name and id of a team channel.
      return options[:api_client].im_list['ims']
    rescue Slack::Web::Api::Error => e # (not_authed)
      options[:api_client].logger.error e
      err_msg = "\nFrom slack_dm_channels_from_rtm_data(API:client.im_list['ims']) = " \
        "e.message: #{e.message}\n" \
        "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
      options[:api_client].logger.error(err_msg)
      return []
    end

    def make_web_client(api_token)
      # Slack.config.token = 'xxxxx'
      Slack.configure do |config|
        config.token = api_token
      end
      Slack::Web::Client.new
    end
=end
    #
  end # module ClassMethods

  #
  #======== INSTANCE METHODS, i.e. User.find_by(1).create_password_token()
  #
  # Code not included in the ClassMethods block or the included block will be
  # included as instance methods.
  # see user_extensions.rb for usage.
end # module UserExtensions
