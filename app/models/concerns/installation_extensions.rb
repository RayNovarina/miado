require 'slack-ruby-client'
# per: https://richonrails.com/articles/rails-4-code-concerns-in-active-record-models
module InstallationExtensions
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
=begin
    #======================
    # DB update for Production release 12/02/2016
    #=======================

    # Trim Installation.rtm_start_json:
    def update_installation_recs
      Installation.all.each do |installation|
        # NOTE: Installation.start_data_from_rtm_start trims out the stuff
        #       we dont want to persist.
        rtm_start_json = start_data_from_rtm_start(installation.bot_api_token)
        next if rtm_start_json.nil?
        installation.update(
          rtm_start_json: rtm_start_json,
          last_activity_type: 'refresh rtm_start_data',
          last_activity_date: DateTime.current)
      end
    end

    # taskbot channels: change channel name, set bot_api_token
    def update_taskbot_channel_recs
      Channel.where(is_taskbot: true).each do |tbot_chan|
      member = Member.where(slack_team_id: tbot_chan.slack_team_id,
                            slack_user_id: tbot_chan.slack_user_id).first
      next if member.nil?
      tbot_chan.update(
        slack_channel_name: "taskbot_channel_for_@#{member.slack_user_name}",
        slack_user_api_token: member.slack_user_api_token,
        bot_api_token: member.bot_api_token,
        bot_user_id: member.bot_user_id)
      end
    end
    #=========
=end

    def update_from_or_create_from(options)
      return update_from_or_create_from_omniauth_callback(options) if options[:source] == :omniauth_callback
    end

    def find_from(options)
      return find_from_omniauth_callback(options) if options[:source] == :omniauth_callback
      return find_from_slack(options) if options[:source] == :slack
    end

    def create_from(options)
      return create_from_omniauth_callback(options) if options[:source] == :omniauth_callback
    end

    # Various methods to support Installations and Team and Members models.

    # Returns: [Installation records]
    def installations(options = {})
      if options.key?(:slack_user_id)
        return Installation.where(slack_team_id: options[:slack_team_id],
                                  slack_user_id: options[:slack_user_id])
      end
      if options.key?(:slack_team_id)
        return Installation.where(slack_team_id: options[:slack_team_id])
      end
      Installation.all
    end

    # Returns: [Installation records]
    def teams
      # Installation.select('DISTINCT ON(slack_team_id) *').reorder('slack_team_id ASC')
      Installation.select('DISTINCT ON(slack_team_id) *').reorder('slack_team_id ASC').order('created_at DESC')
      # Installation.select('DISTINCT ON(slack_team_id, created_at) *').reorder('created_at DESC')
    end

    # Returns: [Channel records]
    def team_channels(options = {})
      Channel.where(slack_team_id: options[:slack_team_id])
             .reorder('slack_channel_name ASC')
    end

    def team_lists(_options = {})
      # options.key?(:slack_team_id)
      []
    end

    # Returns: [Channel records]
    def shared_team_channels(options)
      channels = team_channels(options)
      shared_channels = []
      channels.each do |channel|
        shared_channels << channel unless channel.slack_channel_id.starts_with?('D')
      end
      shared_channels
    end

    # Returns: [Channel records]
    def dm_team_channels(options)
      channels = team_channels(options)
      dm_channels = []
      channels.each do |channel|
        dm_channels << channel if channel.slack_channel_id.starts_with?('D')
      end
      dm_channels
    end

    # Returns: [Channel records]
    def bot_team_channels(options)
      Channel.where(slack_team_id: options[:slack_team_id], is_taskbot: true)
             .reorder('slack_channel_name ASC')
    end

    # Get a new "TRiMMED" copy of the rtm_start data from Slack for this team.
    # Returns: [rtm_start_json, Installation record]
    def refresh_rtm_start_data(options)
      return nil if (installation = installations(options).first).nil?
      return nil if (rtm_start_json = start_data_from_rtm_start(options[:bot_api_token])).nil?
      installation.update(
        rtm_start_json: rtm_start_json,
        last_activity_type: 'refresh rtm_start_data',
        last_activity_date: DateTime.current)
      [rtm_start_json, installation]
    end

    def trim_rtm_start_data(rtm_start_json)
      return nil if rtm_start_json.nil?

      unless rtm_start_json['self'].nil?
        rtm_start_json['self'].except!('prefs', 'groups', 'read_only_channels',
                                       'subteams', 'dnd', 'url')
      end

      unless rtm_start_json['team'].nil?
        rtm_start_json['team'].except!('prefs', 'icon')
      end
      unless rtm_start_json['channels'].nil?
        rtm_start_json['channels'].each do |channel|
          channel.except!('latest', 'members', 'topic', 'purpose')
        end
      end
      unless rtm_start_json['ims'].nil?
        rtm_start_json['ims'].each do |im|
          next if im['latest'].nil?
          im['latest'].except!('text', 'attachments')
        end
      end
      unless rtm_start_json['users'].nil?
        rtm_start_json['users'].each do |user|
          next if user['profile'].nil?
          user['profile'].except!(
            'email', 'image_24', 'image_32', 'image_48', 'image_72',
            'image_192', 'image_512', 'image_1024', 'image_original','fields')
        end
      end
      unless rtm_start_json['bots'].nil?
        rtm_start_json['bots'].each do |bot|
          bot.except!('icons')
        end
      end
      rtm_start_json
    end

    private

    # Returns: Installation record or nil
    def find_from_omniauth_callback(options)
      @view ||= options[:view]
      Installation.where(slack_user_id: options[:request].env['omniauth.auth'].uid,
                         slack_team_id: options[:request].env['omniauth.auth'].info['team_id']
                        ).first
    end

    # Returns: Installation record or nil
    def find_from_slack(options)
      @view ||= options[:view]
      return Installation.where(slack_user_id: options[:slack_user_id],
                                slack_team_id: options[:slack_team_id]
                               ).first if options.key?(:slack_user_id) && options.key?(:slack_team_id)
      return Installation.where(slack_team_id: options[:slack_team_id]
                               ).first if options.key?(:slack_team_id)
      nil
    end

    # Return: installation record with current auth callback info.
    #         If needed, all team member's channels are updated with new install
    #         info.
    def update_from_or_create_from_omniauth_callback(options)
      # Case: We have not authenticated this oauth user before.
      return create_from_omniauth_callback(options) if (installation = find_from_omniauth_callback(options)).nil?
      # Case: We are reinstalling. Update auth info.
      update_auth_info(installation: installation, type: 'reinstallation', request: options[:request])
      installation
    end

    def create_from_omniauth_callback(options)
      auth = options[:request].env['omniauth.auth']
      installation = Installation.new(
        slack_user_id: auth.uid,
        slack_team_id: auth.info['team_id']
      )
      update_auth_info(installation: installation, type: 'installation', request: options[:request])
      installation
    end

    def update_auth_info(options)
      auth = options[:request].env['omniauth.auth']
      options[:installation].update(
        slack_user_api_token: auth.credentials['token'],
        bot_api_token: auth.extra['bot_info']['bot_access_token'],
        bot_user_id: auth.extra['bot_info']['bot_user_id'],
        auth_json: auth,
        auth_params_json: options[:request].env['omniauth.params'],
        rtm_start_json: start_data_from_rtm_start(auth.extra['bot_info']['bot_access_token']),
        last_activity_type: options[:type],
        last_activity_date: DateTime.current
      )
    end

    # Response: TRiMMED array of hashes. Team, users, channels, dms.
    def start_data_from_rtm_start(api_token)
      trim_rtm_start_data(slack_api('rtm.start', api_token))
    end

    def slack_api(method_name, api_token)
      uri = URI.parse('https://slack.com')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new("/api/#{method_name}?token=#{api_token}")
      response = http.request(request)
      JSON.parse(response.body)
    end
  end
end
