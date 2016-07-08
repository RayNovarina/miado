# per: https://richonrails.com/articles/rails-4-code-concerns-in-active-record-models
module ListItemExtensions
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
    #
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
    def new_from_slack_slash_cmd(parsed)
      params = parsed[:url_params]
      ListItem.new(
        description: params[:text],
        channel_id: params[:channel_id],
        channel_name: params[:channel_name],
        command_text:  parsed[:original_command],
        team_domain: params[:team_domain],
        team_id: params[:team_id],
        slack_user_id: params[:user_id],
        slack_user_name: params[:user_name],
        slack_deferred_response_url: params[:response_url]
      )
    end

    def query(p_hash)
      # For ALL team members in ALL channels clumped by channel via sorted by
      # channel name and creation date.

      # open and done: All tasks.
      ListItem.where(team_id: p_hash[:url_params][:team_id])
              .reorder('channel_name ASC, created_at ASC')
    end

    def items(options = {})
      if options.key?(:slack_team_id)
        if options.key?(:slack_channel_id)
          return ListItem.where(team_id: options[:slack_team_id])
                         .where(channel_id: options[:slack_channel_id])
                         .reorder('created_at ASC')
        end
        return ListItem.where(team_id: options[:slack_team_id])
                       .reorder('channel_name ASC, created_at ASC')
      end
      ListItem.all
    end

    def last_activity(options = {})
      if options.key?(:slack_user_id)
        last_active = ListItem.where(team_id: options[:slack_team_id])
                              .where(slack_user_id: options[:slack_user_id])
                              .reorder('updated_at ASC').last
      end
      return last_active.updated_at unless last_active.nil?
      nil
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
