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

    # Returns: [Channel records]
    def channels(options = {})
      return Channel.where(slack_team_id: options[:installation].slack_team_id)
                    .reorder('slack_user_id, is_taskbot, slack_channel_name ASC'
                    ) if options.key?(:installation)
      return Channel.where(slack_user_id: options[:member].slack_user_id)
                    .reorder('is_taskbot, slack_channel_name ASC'
                    ) if options.key?(:member)
      []
    end

    # Returns: String from ActiveRecord count()
    def num_channels(options = {})
      return Channel.where(slack_team_id: options[:installation].slack_team_id)
                    .count if options.key?(:installation)
      return Channel.where(slack_user_id: options[:member].slack_user_id)
                    .count if options.key?(:member)
      '0'
    end

    def last_activity(options = {})
      unless options.key?(:info)
        return nil if (last = last_active(options)).nil?
        return last.last_activity_date
      end
      return nil if options[:info][:last_active_model] == 'User'
      if options[:info][:last_active_model] == 'ListItem'
        args = { slack_team_id: options[:info][:last_active_rec].team_id,
                 slack_channel_id: options[:info][:last_active_rec].channel_id
               }
      elsif options[:info][:last_active_model] == 'Installation'
        args = { slack_team_id: options[:info][:last_active_rec].auth_json['info']['team_id'],
                 slack_user_id: options[:info][:last_active_rec].auth_json['info']['user_id']
               }
      else
        args = { slack_team_id: options[:info][:last_active_rec].slack_team_id,
                 slack_user_id: options[:info][:last_active_rec].slack_user_id
               }
      end
      return nil if (last = last_active(args)).nil?

      { date:  last.last_activity_date,
        type:  last.last_activity_type,
        about: "##{last.slack_channel_name} (#{last.slack_channel_id})"
      }
    end

    def last_active(options = {})
      reorder_clause = 'updated_at DESC'
      if options.key?(:slack_user_id) && options.key?(:slack_team_id)
        last = Channel.where(slack_team_id: options[:slack_team_id],
                             slack_user_id: options[:slack_user_id])
                      .reorder(reorder_clause).first
      elsif options.key?(:slack_channel_id) && options.key?(:slack_team_id)
        last = Channel.where(slack_team_id: options[:slack_team_id],
                             slack_channel_id: options[:slack_channel_id])
                      .reorder(reorder_clause).first
      elsif options.key?(:slack_team_id)
        last = Channel.where(slack_team_id: options[:slack_team_id])
                      .reorder(reorder_clause).first
      elsif options.key?(:slack_user_id)
        last = Channel.where(slack_user_id: options[:slack_user_id])
                      .reorder(reorder_clause).first
      else
        last = Channel.all.reorder(reorder_clause).first
        unless last.nil? || !options.key?(:info)
          return { model: 'Channel',
                   last_active_rec: last,
                   last_active_rec_name: "##{last.slack_channel_name}",
                   last_activity_date: last.last_activity_date || '*none*',
                   last_activity_date_jd: last.last_activity_date.nil? ? 0 : last.last_activity_date.to_s(:number).to_i,
                   last_activity_type: last.last_activity_type || '*none*',
                   last_active_team: Installation.installations(slack_team_id: last.slack_team_id).first.auth_json['info']['team'] }
        end
      end
      last
    end

    def last_taskbot_activity(_options = {})
      nil
    end

    def bot_info(options)
      b_hash = { name: '*no bot*', id: nil, user_id: nil, access_token: nil }
      if options.key?(:installations)
        return b_hash if options[:installations].empty? || options[:installations][0].bot_user_id.nil?
        install_channel = options[:installations][options[:installations].length-1]
      elsif options.key?(:installation)
        return b_hash if options[:installation].nil? ||
                         (install_channel = options[:installation]).bot_user_id.nil?
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
      @view ||= options[:view]
      Channel.new(
        slack_channel_name: options[:slash_url_params]['channel_name'],
        slack_channel_id: options[:slash_url_params]['channel_id'],
        slack_user_id: options[:slash_url_params]['user_id'],
        slack_team_id: options[:slash_url_params]['team_id'],
        is_dm_channel: options[:slash_url_params]['channel_name'] == 'directmessage'
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
        is_dm_channel: true,
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
    #
  end # module ClassMethods

  #
  #======== INSTANCE METHODS, i.e. User.find_by(1).create_password_token()
  #
  # Code not included in the ClassMethods block or the included block will be
  # included as instance methods.
  # see user_extensions.rb for usage.
end # module UserExtensions
