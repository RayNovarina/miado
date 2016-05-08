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

  def welcome_add_to_slack_new
    @view.user = @view.current_user
    @view.team = Team.find_or_create_from(:slack_id, params[:team_id])
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
