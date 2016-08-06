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
    end

    def find_from(options)
      return find_from_slack(options) if options[:source] == :slack
    end

    def create_from(options)
      return create_from_rtm_data(options) if options[:source] == :rtm_data
    end

    # Various methods to support Installations and Team and Members models.

    def team_members(options = {})
      # Case: specified member for specified team, i.e. @dawn on MiaDo Team.
      return Member.where(slack_user_id: options[:slack_user_id],
                          slack_team_id: options[:slack_team_id]
                         ) if options.key?(:slack_user_id) && options.key?(:slack_team_id)
      # Case: all members for specified team, i.e. MiaDo Team.
      return Member.where(slack_team_id: options[:slack_team_id])
                   .reorder('slack_user_name ASC'
                           ) if options.key?(:slack_team_id)
      # Case: all member records.
      Member.all.reorder('slack_team_id ASC, slack_user_name ASC')
    end

    private

    def find_or_create_from_rtm_data(options)
      member = find_from_slack(options)
      return member unless member.nil?
      member = find_from_rtm_data(options)
      return member unless member.nil?
      create_from_rtm_data(options)
    end

    def find_or_create_from_installation(options)
      member = find_from_slack(
        slack_user_id: options[:installation].slack_user_id,
        slack_team_id: options[:installation].slack_team_id)
      return member unless member.nil?
      create_from_installation(options)
    end

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
    def find_from_slack(options)
      return Member.where(slack_user_id: options[:slack_user_id],
                          slack_team_id: options[:slack_team_id]
                         ).first if options.key?(:slack_user_id) && options.key?(:slack_team_id)
      return Member.where(slack_user_name: options[:slack_user_name],
                          slack_team_id: options[:slack_team_id]
                         ).first if options.key?(:slack_user_name) && options.key?(:slack_team_id)
      nil
    end

    # Find member using rtm_start data returned from an installation.
    # Note: usually done for a member name lookup.
    def find_from_rtm_data(options)
      # If user name found for this team and member rec for user_id found,
      # then name change, update member.slack_user_name and real_name.
      nil
    end

    # Returns: member record
    def create_from_installation(options)
      rtm_start = options[:installation].rtm_start_json
      auth_json = options[:installation].auth_json
      user = slack_user_from_rtm_start(rtm_start: rtm_start, slack_user_id: options[:installation].slack_user_id)
      return nil if user.nil?
      member = Member.new(
        slack_user_id: auth_json['info']['user_id'],
        slack_team_id: auth_json['info']['team_id'],
        slack_team_name: auth_json['info']['team'],
        slack_user_name: auth_json['info']['name'].nil? ? auth_json['info']['user'] : auth_json['info']['name'],
        slack_user_real_name: user['profile']['real_name'])
      update_or_create_install_info(member: member, type: 'installation',
                                    auth_json: auth_json, rtm_start: rtm_start)
    end

=begin
member = Member.find_or_create_from(
  source: :rtm_data,
  installation_slack_user_id: parsed[:url_params][:user_id],
  slack_user_name: name,
  slack_team_id: parsed[:url_params][:team_id]
)
=end
    # Returns: member record
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
        # Person using slash cmd has not installed the app but someone one their
        # team has. i.e. Case2.
        # Get install record of anyone on team who has installed app.
        installation = Installation.find_from(
          source: :slack,
          slack_team_id: options[:slack_team_id])
      end
      return nil if installation.nil?
      rtm_start = installation.rtm_start_json
      auth_json = installation.auth_json
      user = slack_user_from_rtm_start(rtm_start: rtm_start, slack_user_name: options[:slack_user_name])
      if user.nil?
        # Case3: member just joined team, has not installed, not in any previous
        # install rec. Get new install info unless not known by Slack.
        rtm_start = start_data_from_rtm_start(auth_json['extra']['bot_info']['bot_access_token'])
        return nil if (user = slack_user_from_rtm_start(rtm_start: rtm_start, slack_user_name: options[:slack_user_name])).nil?
        # update team install recs.
        Installation.where(slack_team_id: installation.slack_team_id)
                    .update_all(rtm_start_json: rtm_start,
                                last_activity_type: 'update_rtm_start',
                                last_activity_date: DateTime.current)
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
        bot_dm_channel_id: find_bot_dm_channel_id_from_rtm_start(
          slack_user_id: options[:member].slack_user_id, rtm_start: options[:rtm_start]),
        bot_msgs_json: bot_msgs_from_rtm_start(
          slack_user_id: options[:member].slack_user_id, rtm_start: options[:rtm_start]),
        last_activity_type: options[:type],
        last_activity_date: DateTime.current)
    end

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

    def find_bot_dm_channel_id_from_rtm_start(options)
      return nil if (im = find_bot_dm_channel_from_rtm_start(
        slack_user_id: options[:slack_user_id],
        rtm_start: options[:rtm_start])).nil?
      im['id']
    end

    # Note: This code is based on the observation of rtm_start data returned
    # when using a bot api token from the miado installer. In that case, the
    # im channels seem to be team bot channels and a matching user_id would be
    # the taskbot channel even if miado is not installed by that user.
    def find_bot_dm_channel_from_rtm_start(options)
      return nil if options[:slack_user_id].nil?
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

    #
  end # module ClassMethods

  #
  #======== INSTANCE METHODS, i.e. User.find_by(1).create_password_token()
  #
  # Code not included in the ClassMethods block or the included block will be
  # included as instance methods.
  # see user_extensions.rb for usage.
end # module UserExtensions
