#
class PagesController < ApplicationController
  before_action :make_view_helper

  def welcome
  end

  def about
  end

  def welcome_new
    @view.user = @view.current_user
  end

  def welcome_back
    @view.user = @view.current_user
  end

  # NOTE: we can load this page standalone for ui testing. If so, create defaults.
  def welcome_add_to_slack_new
    # @view.user = @view.current_user
    @view.user = User.where(email: 'admin@example.com').first
    @view.team = Team.find_from(:slack_id, [@view.user, params[:team_id]])
    @view.provider = OmniauthProvider.all.reorder('updated_at DESC').first
    @view.locals = {
      team: @view.team,
      provider: @view.provider
    }
  end

  def add_to_slack
  end

  def show_header
    return false if @view.name == 'pages-add_to_slack'
    return false if @view.name == 'pages-welcome_add_to_slack_new'
    true
  end

  def show_footer
    # return true unless @view.name == 'pages-add_to_slack'
    # false
    true
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
