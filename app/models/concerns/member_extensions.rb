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

    def find_or_create_from_slack(channel, name)
      member = find_by_slack(channel.user, channel.slack_user_id,
                             channel.slack_team_id, name)
      return member unless member.nil?
      create_from_slack(channel, name, slack_team_id)
    end

    def create_from_slack_name(view, name, slack_team_id)
      @view ||= view
      create_all_from_slack(@view, slack_team_id)
      find_by_name_and_slack_team(@view.user, name, slack_team_id)
    end

    def create_all_from_slack(view, team)
      @view ||= view
      @view.web_client = make_web_client(team.api_token)
      slack_members = slack_members_from_rtm_data
      slack_members.each do |slack_member|
        # next if slack_member[:deleted] ||
        #        slack_member[:name] == 'slackbot'
        next if slack_member[:name] == 'slackbot' || (slack_member[:deleted] && slack_member[:is_bot])
        Member.find_or_create_by(
          name: slack_member[:name],
          slack_user_id: slack_member[:id],
          slack_team_id: slack_member[:team_id],
          is_bot: slack_member[:is_bot],
          deleted: slack_member[:deleted],
          team: team,
          real_name: slack_member[:real_name]
        )
      end
    end

    def all_or_create_all_from_slack(view)
      @view ||= view
      return Member.all if Member.count > 0
      create_all_from_slack(@view)
      Member.all
    end

    def find_by_name_and_slack_team(user, name, slack_team_id)
      Member.where(team: Team.where(user: user, slack_team_id: slack_team_id).first,
                   name: name).first
    end

    private

    def slack_members_from_rtm_data
      # response is an array of hashes. Each has name and id of a team member.
      begin
        return @view.web_client.users_list['members']
      rescue Slack::Web::Api::Error => e
        @view.web_client.logger.error e
        @view.web_client.logger.error "\ne.message: #{e.message}\n" \
          "@view.team - name: #{@view.team.name}" \
          "api_token: #{Slack.config.token}\n"
        return @view.exception = e
      end
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
