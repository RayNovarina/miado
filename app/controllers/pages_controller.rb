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
    @view.team = Team.last
  end

  def add_to_slack
  end

  def show_header
    return true unless @view.name == 'pages-add_to_slack'
    false
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
