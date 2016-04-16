#
class Api::Slack::Slash::CommandsController < Api::Slack::Slash::BaseController
  # before_action :authenticate_user
  # before_action :authorize_user

  # Slash commands are handed off to the bot process generally.
  # Static page responses are directly sent here to be more responsive to user.
  # Returns json slash command response. Empty text msg if command handed off
  # to bot.
  def create
    head 200
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
