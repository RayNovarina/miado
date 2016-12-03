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
      return find_or_create_from_wordpress(options) if options[:source] == :wordpress
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

    def find_taskbot_channel_from(options)
      return find_taskbot_channel_from_slack(options) if options[:source] == :slack
    end

    def find_or_create_taskbot_channel_from(options)
      return find_or_create_taskbot_channel_from_slack(options) if options[:source] == :slack
      return find_or_create_taskbot_channel_from_installation(options) if options[:source] == :installation
    end

    # Various methods to support Installations and Team and Members models.

    def last_activity(options = {})
      # if options.key?(:slack_user_id)
      #  return Channel.where(slack_team_id: options[:slack_team_id])
      #                .where(updated_by_slack_user_id: options[:slack_user_id])
      #                .reorder('updated_at ASC').last.updated_at
      # end
      if options.key?(:slack_team_id)
        last_active = Channel.where(slack_team_id: options[:slack_team_id])
                             .last
        # .reorder('updated_at ASC').last
      end
      if options.key?(:user)
        last_active = Channel.all.last
        # .reorder('updated_at ASC').last
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
      b_hash[:id] =
        install_channel.rtm_start_json['users']
        .map { |user| user['id'] == b_hash[:user_id] ? user['profile']['bot_id'] : nil }
        .compact[0]
      return b_hash if b_hash[:id].nil?
      b_hash[:name] =
        install_channel.rtm_start_json['bots']
        .map { |bot| bot['id'] == b_hash[:id] ? bot['name'] : nil }
        .compact[0]
      b_hash
    end

    # Response: TRIMMED array of hashes. Team, users, channels, dms.
    def start_data_from_rtm_start(api_token)
      Installation.trim_rtm_start_data(slack_api('rtm.start', api_token))
    end

    def slack_api(method_name, api_token)
      uri = URI.parse('https://slack.com')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new("/api/#{method_name}?token=#{api_token}")
      response = http.request(request)
      JSON.parse(response.body)
    end

    private

    # Returns: Channel record.
    def find_or_create_from_slack(options)
      if (channel = find_from_slack(options)).nil?
        # Case: This channel has not been accessed before.
        channel = create_from_slack(options)
      end
      channel
    end

    # Returns: Channel record.
    def find_or_create_from_wordpress(options)
      if (channel = find_from_wordpress(options)).nil?
        # Case: This channel has not been accessed before.
        channel = create_from_wordpress(options)
      end
      channel
    end

    # Returns: taskbot Channel record.
    def find_or_create_taskbot_channel_from_slack(options)
      if (taskbot_channel = find_taskbot_channel_from_slack(options)).nil?
        # Case: This channel has not been accessed before.
        taskbot_channel = create_taskbot_channel_from_slack(options)
      end
      taskbot_channel
    end

    # Returns: taskbot Channel record.
    def find_or_create_taskbot_channel_from_installation(options)
      if (taskbot_channel = find_taskbot_channel_from_installation(options)).nil?
        # Case: This channel has not been accessed before.
        taskbot_channel = create_taskbot_channel_from_installation(options)
      end
      taskbot_channel
    end

    # Return: install channel with current auth callback info.
    #         If needed, all team members channels are updated with new install
    #         info.
    def update_from_or_create_from_omniauth_callback(options)
      install_channel = create_or_update_install_channel(options)
      update_members_hash_for_all_team_members(
        slack_team_id: install_channel.slack_team_id,
        members_hash: install_channel.members_hash)
      install_channel
    end

    # Return: install channel
    def create_or_update_install_channel(options)
      # Case: We have not authenticated this oauth user before.
      return create_install_channel_from_omniauth_callback(options) if (install_channel = find_from_omniauth_callback(options)).nil?
      # Case: We are reinstalling. Update auth info.
      update_channel_auth_info(install_channel, options)
      # Update fields changed by reinstall for all team channels for this user.
      update_channel_reinstall_info(install_channel: install_channel)
      install_channel
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
    # Update fields changed by reinstall for just the team channels for the
    # installing member.
    def update_channel_reinstall_info(options)
      Channel.where(slack_user_id: options[:install_channel].slack_user_id)
             .where(slack_team_id: options[:install_channel].slack_team_id)
             .update_all(slack_user_api_token: options[:install_channel].slack_user_api_token,
                         bot_api_token: options[:install_channel].bot_api_token,
                         bot_user_id: options[:install_channel].bot_user_id,
                         last_activity_type: 'reinstallation',
                         last_activity_date: DateTime.current)
    end

    # Return: install channel record
    def find_from_omniauth_callback(options)
      @view ||= options[:view]
      Channel.where(slack_channel_name: 'installation',
                    slack_user_id: options[:request].env['omniauth.auth'].uid,
                    slack_team_id: options[:request].env['omniauth.auth'].info['team_id']).first
    end

    # Return: new install Channel record
    def create_install_channel_from_omniauth_callback(options)
      auth = options[:request].env['omniauth.auth']
      channel = Channel.new(
        slack_channel_name: 'installation',
        slack_channel_id: '',
        slack_user_id: auth.uid,
        slack_team_id: auth.info['team_id'],
        last_activity_type: 'installation',
        last_activity_date: DateTime.current
      )
      update_channel_auth_info(channel, options)
      channel
    end

    # Return: Channel record
    def find_from_slack(options)
      @view ||= options[:view]
      Channel.where(slack_user_id: options[:slash_url_params]['user_id'],
                    slack_team_id: options[:slash_url_params]['team_id'],
                    slack_channel_id: options[:slash_url_params]['channel_id']).first
    end

    # Return: new Channel record
    def create_from_slack(options)
      # Can not happen if normal install/not in dev testing but a taskbot
      # channel can be detected if we look it up in the installation.rtm_start
      # data?
      # slack_channel_name: "directmessage",
      # slack_channel_id: "D18FG2WUQ",
      # return create_taskbot_channel_from_slack(options) if options[:slash_url_params]['channel_name'] == 'directmessage' &&
      #                                                      it is a taskbot channel.
      @view ||= options[:view]
      Channel.new(
        slack_channel_name: options[:slash_url_params]['channel_name'],
        slack_channel_id: options[:slash_url_params]['channel_id'],
        slack_user_id: options[:slash_url_params]['user_id'],
        slack_team_id: options[:slash_url_params]['team_id']
      )
    end

    # Return: Channel record
    def find_from_wordpress(options)
      @view ||= options[:view]
      return nil if (target_member = Member.find_from(source: :wordpress,
                                                      view: @view,
                                                      slash_url_params: options[:slash_url_params])
                    ).nil?
      Channel.where(slack_user_id: target_member.slack_user_id,
                    slack_team_id: target_member.slack_team_id,
                    slack_channel_name: options[:slash_url_params][:channel_name]).first
    end

    # Return: new Channel record
    def create_from_wordpress(options)
      @view ||= options[:view]
      return nil if (target_member = Member.find_from(source: :wordpress,
                                                      view: @view,
                                                      slash_url_params: options[:slash_url_params])
                    ).nil?
      Channel.new(
        slack_channel_name: options[:slash_url_params]['channel_name'],
        slack_channel_id: options[:slash_url_params]['channel_id'],
        slack_user_id: target_member.slack_user_id,
        slack_team_id: target_member.slack_team_id
      )
    end

    # Return: Channel record
    def find_taskbot_channel_from_installation(options)
      Channel.where(is_taskbot: true,
                    slack_user_id: options[:installation].slack_user_id,
                    slack_team_id: options[:installation].slack_team_id).first
    end

    # Return: new Channel record
    def create_taskbot_channel_from_installation(options)
      # m_hash = options[:installation].members_hash[options[:slack_user_id]]
      member = Member.find_from(source: :installation, installation: options[:installation])
      Channel.create!(
        is_taskbot: true,
        slack_channel_name: "taskbot_channel_for_@#{member.slack_user_name}",
        slack_channel_id: member.bot_dm_channel_id,
        slack_user_id: member.slack_user_id,
        slack_team_id: member.slack_team_id,
        slack_user_api_token: member.slack_user_api_token,
        bot_api_token: member.bot_api_token,
        bot_user_id: member.bot_user_id
      )
    end

    # Return: Channel record
    def find_taskbot_channel_from_slack(options)
      if options.key?('channel_id')
        return Channel.where(
          is_taskbot: true,
          slack_channel_id: options[:slash_url_params]['channel_id'],
          slack_user_id: options[:slash_url_params]['user_id'],
          slack_team_id: options[:slash_url_params]['team_id']).first
      end
      Channel.where(is_taskbot: true,
                    slack_user_id: options[:slash_url_params]['user_id'],
                    slack_team_id: options[:slash_url_params]['team_id']).first
    end

    # Return: new Channel record
    def create_taskbot_channel_from_slack(options)
      installation = Installation.find_from(
        source: :slack, view: @view,
        slack_user_id: options[:slash_url_params]['user_id'],
        slack_team_id: options[:slash_url_params]['team_id'])
      create_taskbot_channel_from_installation(installation: installation)
    end

=begin

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
#=========================
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

    # Note: This code is based on the observation of rtm_start data returned
    # when using a bot api token from the miado installer. In that case, the
    # im channels seem to be team bot channels and a matching user_id would be
    # the taskbot channel even if miado is not installed by that user.
    def find_bot_dm_channel_from_rtm_start(options)
      return nil if options[:bot_channel_slack_user_id].nil?
      slack_dm_channels = options[:rtm_start]['ims']
      slack_dm_channels.each do |im|
        next if im[:is_user_deleted]
        return im if im['user'] == options[:bot_channel_slack_user_id]
      end
      nil
    end

        # update install/reinstall info for all team members.
        def update_members_hash_for_all_team_members(options)
          Channel.where(slack_team_id: options[:slack_team_id])
                 .update_all(members_hash: options[:members_hash])
        end

        # Returns: [members_hash, rtm_start]
        def find_or_create_members_hash_from_omniauth_callback(options)
          auth = options[:request].env['omniauth.auth']
          rtm_start = start_data_from_rtm_start(auth.extra['bot_info']['bot_access_token'])
          create_members_hash_from_rtm_start(auth: auth, rtm_start: rtm_start)
          # other_install_channel =
          #  Channel.where(slack_channel_name: 'installation',
          #                slack_team_id: auth.info['team_id'])
          #         .where.not(slack_user_id: auth.uid).first
          # return create_members_hash_from_rtm_start(auth: auth, rtm_start: rtm_start) if other_install_channel.nil?
          # members_hash = other_install_channel.members_hash
          # update_members_hash_for_reinstall_from_rtm_start(members_hash: members_hash, auth: auth,
          #                                   rtm_start: rtm_start)
          # update_members_hash_from_omniauth_callback(members_hash: members_hash,
          #                                           auth: auth)
        end

        # Member is reinstalling MiaDo. tokens need to be updated in the members_hash.
        # Returns: [members_hash, rtm_start]
        def update_members_hash_for_reinstall_from_rtm_start(options)
          auth = options[:auth]
          members_hash = options[:members_hash]
          rtm_start = options[:rtm_start]
          # Replace installing member's updated info in existing team lookup hash.
          add_new_member_to_hash(
            members_hash: members_hash,
            rtm_start: rtm_start,
            name: auth.info['user'],
            real_name: auth.info['user'],
            id: auth.uid
          )
          [members_hash, rtm_start]
        end

        def add_new_member_to_hash(options)
          m_hash =
            { slack_user_name: options[:name],
              slack_real_name: options[:real_name],
              slack_user_id: options[:id],
              bot_dm_channel_id: nil
            }
          unless (im = find_bot_dm_channel_from_rtm_start(
            bot_channel_slack_user_id: options[:bot_channel_slack_user_id],
            rtm_start: options[:rtm_start])).nil?
            m_hash[:bot_dm_channel_id] = im['id']
            # m_hash[:bot_msg_id] = nil if im['latest'].nil?
            # m_hash[:bot_msg_id] = im['latest']['ts'] unless im['latest'].nil?
          end
          options[:members_hash][m_hash[:slack_user_name]] = m_hash
          options[:members_hash][m_hash[:slack_user_id]] = m_hash
        end

        # Returns: [members_hash, rtm_start]
        def create_members_hash_from_rtm_start(options)
          # auth = options[:auth]
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
              # Set bot channel id only for installing member. Block taskbot msgs
              # from others till they install miado.
              # bot_channel_slack_user_id: slack_member['id'] == auth.uid ? slack_member['id'] : nil,
              # api_token: slack_member['id'] == auth.uid ? auth.credentials['token'] : nil,
              # bot_user_id: slack_member['id'] == auth.uid ? auth.extra['bot_info']['bot_user_id'] : nil,
              # bot_api_token: slack_member['id'] == auth.uid ? auth.extra['bot_info']['bot_access_token'] : nil
            )
          end
          [members_hash, rtm_start]
        end

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
