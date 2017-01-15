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

    #======================
    # DB update for Production update 01/??/2017
    #=======================

    def update_dm_channel_recs
      installation, im_list, member = nil
      Channel.all.each do |channel|
        if channel.is_taskbot
          update_taskbot_channel(channel)
        elsif channel.slack_channel_name == 'directmessage'
          installation, im_list, member = update_dm_channel(channel, installation, im_list, member)
        else
          update_public_channel(channel)
        end
      end
    end

    def update_dm_channel(channel, installation, im_list, member)
      channel.update(
        is_dm_channel: true)
    end

    def update_taskbot_channel(channel)
      channel.update(
        is_dm_channel: true)
    end

    def update_public_channel(channel)
      channel.update(
        is_dm_channel: false)
    end
    #====================================

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
      if options.key?(:member)
        return Installation.where(slack_team_id: options[:member].slack_team_id,
                                  slack_user_id: options[:member].slack_user_id)
      end
      # Must be All option.
      if options[:sort_by] == 'alpha'
        return Installation.reorder("auth_json -> 'info' -> 'team' ASC")
      elsif options[:sort_by] == 'activity'
        return Installation.reorder('last_activity_date DESC')
      end
      Installation.reorder('created_at DESC')
    end

    # Returns: String from ActiveRecord count()
    def num_installations(options = {})
      if options.key?(:slack_team_id)
        return Installation.where(slack_team_id: options[:slack_team_id]).count
      end
      Installation.count
    end

    # Returns: [Installation records]
    def teams
      # Installation.select('DISTINCT ON(slack_team_id) *').reorder('slack_team_id ASC')
      Installation.select('DISTINCT ON(slack_team_id) *').reorder('slack_team_id ASC').order('created_at DESC')
      # Installation.select('DISTINCT ON(slack_team_id, created_at) *').reorder('created_at DESC')
    end

    # Returns: String from ActiveRecord count()
    def num_teams(_options = {})
      Installation.select('DISTINCT ON(slack_team_id) *').reorder('').length.to_s
    end

    def last_active(options = {})
      reorder_clause = 'updated_at DESC'
      last = Installation.all.reorder(reorder_clause).first
      unless last.nil? || !options.key?(:info)
        return { last_active_model: 'Installation',
                 last_active_rec: last,
                 last_active_rec_name: '',
                 last_activity_date: last.last_activity_date || '*none*',
                 last_activity_date_jd: last.last_activity_date.nil? ? '*none*' : last.last_activity_date.to_s(:number).to_i,
                 last_activity_type: last.last_activity_type || '*none*',
                 last_active_team: last.auth_json['info']['team'] }
      end
      last
    end

    def slack_api(method_name, api_token)
      uri = URI.parse('https://slack.com')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new("/api/#{method_name}?token=#{api_token}")
      response = http.request(request)
      JSON.parse(response.body)
    end

    # Response: TRiMMED array of hashes. Team, users, channels, dms.
    def start_data_from_rtm_start(api_token)
      trim_rtm_start_data(slack_api('rtm.start', api_token))
    end

    # Inputs: api_token
    # Returns: slack im_list object
    def ims_from_im_list(api_token)
      slack_api('im.list', api_token)['ims']
    end

    # Get a new "TRIMMED" copy of the rtm_start data from Slack for this team.
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

    # Note: This code is based on the observation of rtm_start data returned
    # when using a bot api token from the miado installer. In that case, the
    # im channels seem to be team bot channels and a matching user_id would be
    # the taskbot channel even if miado is not installed by that user.
    # NOTE: if a bot token is used, the slack_user_id will find the Taskbot DM
    #       channel for that user. IF a user token is used, the slack_user_id
    #       will return the user's dm channel.
    # Returns: slackUserObj{}
    def slack_user_from_rtm_start(options)
      options[:rtm_start]['users'].each do |user|
        if options.key?(:slack_user_id)
          next unless user['id'] == options[:slack_user_id]
        elsif options.key?(:slack_user_name)
          next unless user['name'] == options[:slack_user_name]
        end
        return user
      end
      nil
    end

    # Inputs: slack_user_id
    # Returns: slackDMchanObj{}
    def slack_user_dm_chan_from_rtm_start(options)
      find_dm_channel_from_rtm_start(
        slack_user_id: options[:slack_user_id],
        rtm_start: options[:rtm_start])
    end

    # Inputs: slack_user_id
    # Returns: [msg{}]
    def bot_msgs_from_rtm_start(options)
      msgs = []
      options[:rtm_start]['ims'].each do |im|
        next if im[:is_user_deleted]
        next unless im['user'] == options[:slack_user_id]
        next unless im.key?('latest')
        next if im['latest'].nil?
        msgs << {
          'text' => im['latest']['text'],
          'username' => im['latest']['username'],
          'bot_id' => im['latest']['bot_id'],
          'type' => im['latest']['type'],
          'subtype' => im['latest']['subtype'],
          'ts' => im['latest']['ts']
        }
      end
      msgs
    end

    # Inputs: rtm_start, slack_user_id
    # Returns: String
    def find_bot_dm_channel_id_from_rtm_start(options)
      return nil if (im = find_dm_channel_from_rtm_start(
        slack_user_id: options[:slack_user_id],
        rtm_start: options[:rtm_start])).nil?
      im['id']
    end

=begin
im_list = Installation.slack_api('im.list', installation.bot_api_token)
=> {"ok"=>true,
 "ims"=>
  [{"id"=>"D18F7T2TW", "created"=>1463082203, "is_im"=>true, "is_org_shared"=>false, "user"=>"USLACKBOT", "is_user_deleted"=>false},
   {"id"=>"D18E3GH2P", "created"=>1463082203, "is_im"=>true, "is_org_shared"=>false, "user"=>"U0VLZ5P51", "is_user_deleted"=>false},
   {"id"=>"D18FG2WUQ", "created"=>1463082204, "is_im"=>true, "is_org_shared"=>false, "user"=>"U0VNMUXNZ", "is_user_deleted"=>false},
   {"id"=>"D18FV4PAN", "created"=>1463082204, "is_im"=>true, "is_org_shared"=>false, "user"=>"U17DNLFQ9", "is_user_deleted"=>false},
   {"id"=>"D18E3GHEX", "created"=>1463082204, "is_im"=>true, "is_org_shared"=>false, "user"=>"U17DUJVGA", "is_user_deleted"=>false},
   {"id"=>"D18E3GHLK", "created"=>1463082204, "is_im"=>true, "is_org_shared"=>false, "user"=>"U17DUPQDQ", "is_user_deleted"=>false}]}
=end
  # Inputs: im_list, slack_channel_id
    def find_dm_channel_from_im_list(options)
      return nil if options.key?(:im_list) && options[:im_list].nil?
      return nil if options.key?(:slack_channel_id) && options[:slack_channel_id].nil?
      options[:im_list].each do |im|
        next if im['is_user_deleted']
        return im if im['id'] == options[:slack_channel_id]
      end
      nil
    end

    # Note: This code is based on the observation of rtm_start data returned
    # when using a bot api token from the miado installer. In that case, the
    # im channels seem to be team bot channels and a matching user_id would be
    # the taskbot channel even if miado is not installed by that user.
    # NOTE: if a bot token is used, the slack_user_id will find the Taskbot DM
    #       channel for that user. IF a user token is used, the slack_user_id
    #       will return the user's dm channel.
    #
    # Inputs: rtm_start, (slack_user_id or slack_channel_id)
    # Returns: slackImObj{} or nil
    def find_dm_channel_from_rtm_start(options)
      return nil if options.key?(:slack_user_id) && options[:slack_user_id].nil?
      return nil if options.key?(:slack_channel_id) && options[:slack_channel_id].nil?
      slack_dm_channels = options[:rtm_start]['ims']
      slack_dm_channels.each do |im|
        next if im[:is_user_deleted]
        return im if options.key?(:slack_user_id) && im['user'] == options[:slack_user_id]
        return im if options.key?(:slack_channel_id) && im['id'] == options[:slack_channel_id]
      end
      nil
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
  end
end
