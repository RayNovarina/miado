require 'slack-ruby-client'
# per: https://richonrails.com/articles/rails-4-code-concerns-in-active-record-models
module MemberExtensions
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

    def update_from_or_create_from(options)
      return update_from_or_create_from_installation(options) if options[:source] == :installation
    end

    def find_or_create_from(options)
      return find_or_create_from_installation(options) if options[:source] == :installation
      return find_or_create_from_rtm_data(options) if options[:source] == :rtm_data
      return find_or_create_from_slack(options) if options[:source] == :slack
    end

    def find_from(options)
      return find_from_slack(options) if options[:source] == :slack
      return find_from_wordpress(options) if options[:source] == :wordpress
      return find_from_installation(options) if options[:source] == :installation
    end

    def create_from(options)
      return create_from_rtm_data(options) if options[:source] == :rtm_data
    end

    # Various methods to support Installations and Team and Members models.

    # Returns: [Member records]
    def members(options = {})
      # Case: specified member for specified team, i.e. @dawn on MiaDo Team.
      return Member.where(slack_user_id: options[:slack_user_id],
                          slack_team_id: options[:slack_team_id]
                         ) if options.key?(:slack_user_id) && options.key?(:slack_team_id)
      # Case: all members for specified team, i.e. MiaDo Team.
      return Member.where(slack_team_id: options[:slack_team_id]
                         ) if options.key?(:slack_team_id)
      return Member.where(slack_team_id: options[:installation].slack_team_id)
                   .reorder('slack_user_name ASC'
                           ) if options.key?(:installation)
      # Case: all member records.
      Member.all.reorder('slack_team_id ASC, slack_user_name ASC')
    end

    # Returns: String from ActiveRecord count()
    def num_members(options = {})
      return Member.where(slack_team_id: options[:installation].slack_team_id)
                   .count if options.key?(:installation)
      '0'
    end

    def last_active(options = {})
      reorder_clause = 'updated_at DESC'
      last = Member.all.reorder(reorder_clause).first
      unless last.nil? || !options.key?(:info)
        return { last_active_model: 'Member',
                 last_active_rec: last,
                 last_active_rec_name: "@#{last.slack_user_name}",
                 last_activity_date: last.last_activity_date || '*none*',
                 last_activity_date_jd: last.last_activity_date.nil? ? '*none*' : last.last_activity_date.to_s(:number).to_i,
                 last_activity_type: last.last_activity_type || '*none*',
                 last_active_team: Installation.installations(slack_team_id: last.slack_team_id).first.auth_json['info']['team'] }
      end
      last
    end

    private

    # Returns: Member record or nil
    def find_or_create_from_rtm_data(options)
      member = find_from_slack(options)
      return member unless member.nil?
      member = find_from_rtm_data(options)
      return member unless member.nil?
      create_from_rtm_data(options)
    end

    # Returns: Member record or nil
    def find_or_create_from_installation(options)
      member = find_from_installation(options)
      return member unless member.nil?
      create_from_installation(options)
    end

    # Returns: Member record or nil
    def find_or_create_from_slack(options)
      member = find_from_slack(
        slack_user_id: options[:slash_url_params]['user_id'],
        slack_team_id: options[:slash_url_params]['team_id'])
      return member unless member.nil?
      create_from_rtm_data(
        installation_slack_user_id: options[:slash_url_params]['user_id'],
        slack_team_id: options[:slash_url_params]['team_id'],
        slack_user_name: options[:slash_url_params]['user_name'])
    end

    # Returns: Member record or nil
    def update_from_or_create_from_installation(options)
      # Case: User has not installed before.
      return create_from_installation(options) if (member = find_from_slack(
        slack_user_id: options[:installation].slack_user_id,
        slack_team_id: options[:installation].slack_team_id)).nil?
      # Update fields changed by reinstall for all team members of this user.
      update_or_create_install_info(member: member, type: 'reinstallation',
                                    auth_json: options[:installation].auth_json,
                                    rtm_start: options[:installation].rtm_start_json)
      member
    end

    # Find member using slack slash cmd info.
    # Returns: Member record or nil
    def find_from_slack(options)
      return Member.where(slack_user_id: options[:slack_user_id],
                          slack_team_id: options[:slack_team_id]
                         ).first if options.key?(:slack_user_id) && options.key?(:slack_team_id)
      return Member.where(slack_user_name: options[:slack_user_name],
                          slack_team_id: options[:slack_team_id]
                         ).first if options.key?(:slack_user_name) && options.key?(:slack_team_id)
      nil
    end

    # Returns: Member record or nil
    def find_from_installation(options)
      find_from_slack(
        slack_user_id: options[:installation].slack_user_id,
        slack_team_id: options[:installation].slack_team_id)
    end

    # Find member using rtm_start data returned from an installation.
    # Note: usually done for a member name lookup.
    # Returns: Member record or nil
    def find_from_rtm_data(options)
      # If user name found for this team and member rec for user_id found,
      # then name change, update member.slack_user_name and real_name.
      nil
    end

    # Find member using wordpress slash cmd info.
    # Returns: Member record or nil
    def find_from_wordpress(options)
      Member.where(slack_team_name: options[:slash_url_params][:team_domain],
                   slack_user_name: options[:slash_url_params][:user_name]).first
    end

    # Returns: member record
    def create_from_installation(options)
      rtm_start = options[:installation].rtm_start_json
      auth_json = options[:installation].auth_json
      user = Installation.slack_user_from_rtm_start(rtm_start: rtm_start, slack_user_id: options[:installation].slack_user_id)
      return nil if user.nil?
      member = Member.new(
        slack_user_id: auth_json['info']['user_id'],
        slack_team_id: auth_json['info']['team_id'],
        slack_team_name: auth_json['info']['team'],
        slack_user_name: auth_json['info']['name'].nil? ? auth_json['info']['user'] : auth_json['info']['name'],
        slack_user_real_name: user['profile']['real_name'])
      update_or_create_install_info(member: member, type: 'installation',
                                    auth_json: auth_json, rtm_start: rtm_start)
      member
    end

    # Inputs: options = { :installation_slack_user_id, :slack_team_id, :slack_user_name }
    # Returns: member record or nil
    # Case1: ray installs, mentions @dawnnova: look her up in ray's install rec.
    # Case2: dawn has not installed, uses /do @sue: look her up in any team member's install rec.
    # Case3: ralph just joined team, has not installed, uses /do @sue: he is not
    #        in any previous install rec. Get new install info, update team
    #        install recs. OR it could just be a wrong name, i.e. a typo.
    def create_from_rtm_data(options)
      # Has slash cmd user installed app? i.e. Case1: ray installs,
      # mentions @dawnnova: look her up in ray's install rec.
      installation = Installation.find_from(
        source: :slack,
        slack_user_id: options[:installation_slack_user_id],
        slack_team_id: options[:slack_team_id])
      if installation.nil?
        # Person using slash cmd has not installed the app but someone one
        # on their team has. i.e. Case2.
        # Get install record of anyone on team who has installed app.
        installation = Installation.find_from(
          source: :slack,
          slack_team_id: options[:slack_team_id])
      end
      return nil if installation.nil?
      rtm_start = installation.rtm_start_json
      auth_json = installation.auth_json
      user = Installation.slack_user_from_rtm_start(rtm_start: rtm_start, slack_user_name: options[:slack_user_name])
      if user.nil?
        # Case3: member just joined team, has not installed, not in any previous
        # install rec. Get new install info unless not known by Slack.
        rtm_start = Installation.start_data_from_rtm_start(auth_json['extra']['bot_info']['bot_access_token'])
        return nil if (user = Installation.slack_user_from_rtm_start(rtm_start: rtm_start, slack_user_name: options[:slack_user_name])).nil?
        # update team install recs.
        Installation.where(slack_team_id: installation.slack_team_id)
                    .update_all(rtm_start_json: rtm_start,
                                last_activity_type: 'update_rtm_start',
                                last_activity_date: DateTime.current).first
      end
      member = Member.create!(
        slack_user_id: user['id'],
        slack_team_id: options[:slack_team_id],
        slack_team_name: auth_json['info']['team'],
        slack_user_name: options[:slack_user_name],
        slack_user_real_name: user['profile']['real_name'],
        last_activity_type: 'created via lookup',
        last_activity_date: DateTime.current
      )
      if member.slack_user_id == installation.slack_user_id
        # We are making a member record for someone who has installed app.
        update_or_create_install_info(member: member, type: 'created via lookup',
                                      auth_json: auth_json, rtm_start: rtm_start)
      end
      member
    end

    def update_or_create_install_info(options)
      options[:member].update(
        slack_user_api_token: options[:auth_json]['credentials']['token'],
        bot_api_token: options[:auth_json]['extra']['bot_info']['bot_access_token'],
        bot_user_id: options[:auth_json]['extra']['bot_info']['bot_user_id'],
        bot_dm_channel_id: Installation.find_bot_dm_channel_id_from_rtm_start(
          slack_user_id: options[:member].slack_user_id, rtm_start: options[:rtm_start]),
        bot_msgs_json: Installation.bot_msgs_from_rtm_start(
          slack_user_id: options[:member].slack_user_id, rtm_start: options[:rtm_start]),
        last_activity_type: options[:type],
        last_activity_date: DateTime.current)
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
