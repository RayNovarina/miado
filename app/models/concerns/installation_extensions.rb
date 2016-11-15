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
    # class ConvertProvidersToInstallations < ActiveRecord::Migration
    #  class OmniauthProvider < ActiveRecord::Base
    #  end
    #
    def up
      Installation.destroy_all
      Channel.installations.each do |install_channel|
        # def create_from_omniauth_callback(options)
        auth = install_channel.auth_json
        installation = Installation.new(
          slack_user_id: auth['uid'],
          slack_team_id: auth['info']['team_id'])
        # update_auth_info(installation: installation, type: 'installation', request: options[:request])
        # def update_auth_info(options)
        installation.update(
          slack_user_api_token: auth['credentials']['token'],
          bot_api_token: auth['extra']['bot_info']['bot_access_token'],
          bot_user_id: auth['extra']['bot_info']['bot_user_id'],
          auth_json: auth,
          auth_params_json: install_channel.auth_params_json,
          rtm_start_json: install_channel.rtm_start_json,
          last_activity_type: 'installation',
          last_activity_date: DateTime.current)
        installation.rtm_start_json['users'].each do |slack_member|
          next if slack_member['name'] == 'slackbot' || slack_member['deleted'] || slack_member['is_bot']
          Member.find_or_create_from(
            source: :rtm_data,
            installation_slack_user_id: installation.slack_user_id,
            slack_user_name: slack_member['name'],
            slack_team_id: installation.slack_team_id
          )
        end
      end
      Channel.installations.destroy_all
      Channel.update_all(slack_user_api_token: nil,
                         bot_api_token: nil,
                         members_hash: nil,
                         bot_user_id: nil)
    end
    # end
    #=====================
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
                           .reorder('slack_team_id ASC')
      end
      if options.key?(:slack_team_id)
        return Installation.where(slack_team_id: options[:slack_team_id])
                           .reorder('slack_team_id ASC')
      end
      Installation.all.reorder('slack_team_id ASC')
    end

    # Returns: [Installation records]
    def teams
      Installation.select('DISTINCT ON(slack_team_id)*')
                  .reorder('slack_team_id ASC')
    end

    # Get a new copy of the rtm_start data from Slack for this team.
    # Returns: [rtm_start_json, Installation record]
    def refresh_rtm_start_data(options)
      return nil if (installation = installations(options).first).nil?
      return nil if (rtm_start_json = start_data_from_rtm_start(options[:bot_api_token])).nil?
      installation.update(
        rtm_start_json: trim_rtm_start_data(rtm_start_json),
        last_activity_type: 'refresh rtm_start_data',
        last_activity_date: DateTime.current)
      [rtm_start_json, installation]
    end

    private

    def trim_rtm_start_data(rtm_start_json)
      rtm_start_json['self']['prefs'] = {} unless rtm_start_json ['self'].nil?

      unless rtm_start_json['team'].nil?
        rtm_start_json['team']['prefs'] = {}
        rtm_start_json['team']['icon'] = {}
      end

      unless rtm_start_json['channels'].nil?
        rtm_start_json['channels'].each do |channel|
          channel['latest'] = {}
          channel['members'] = []
          channel['topic'] = {}
          channel['purpose'] = {}
        end
      end

      rtm_start_json['groups'] = []

      unless rtm_start_json['ims'].nil?
        rtm_start_json['ims'].each do |im|
          next if im['latest'].nil?
          im['latest']['text'] = ''
          im['latest']['attachments'] = []
        end
      end

      rtm_start_json['read_only_channels'] = []
      rtm_start_json['subteams'] = {}
      rtm_start_json['dnd'] = {}

      unless rtm_start_json['users'].nil?
        rtm_start_json['users'].each do |user|
          next if user['profile'].nil?
          user['profile']['image_24'] = ''
          user['profile']['image_32'] = ''
          user['profile']['image_48'] = ''
          user['profile']['image_72'] = ''
          user['profile']['image_192'] = ''
          user['profile']['image_512'] = ''
          user['profile']['image_1024'] = ''
          user['profile']['image_original'] = ''
          user['profile']['fields'] = nil
        end
      end

      unless rtm_start_json['bots'].nil?
        rtm_start_json['bots'].each do |bot|
          bot['icons'] = {}
        end
      end

      rtm_start_json['url'] = ''

      rtm_start_json
    end

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

    # response is an array of hashes. Team, users, channels, dms.
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
