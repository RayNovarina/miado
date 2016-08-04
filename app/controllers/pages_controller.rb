#
class PagesController < ApplicationController
  before_action :make_view_helper

  def root
    @view.user = @view.current_user
  end

  def admin
  end

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

  # NOTE: we can load this page standalone for ui testing. If so, use defaults.
  # If loaded as part of install, we get here via:
  #    Redirected to http://localhost:3000/welcome/add_to_slack_new?installation_db_id=1
  def welcome_add_to_slack_new
    # Note: current_user invalid because no one is logged in for an install.
    @view.user = User.where(email: 'admin@example.com').first
    installation = Installation.find(params[:installation_db_id]) unless params[:installation_db_id].nil?
    installation = nil if params[:installation_db_id].nil?
    @view.locals = {
      installation: installation
    }
  end

  def add_to_slack
  end

  def use_asset_pipeline
    return true if @view.user_signed_in? && @view.name == 'pages-add_to_slack'
    return false if @view.name == 'pages-add_to_slack'
    return false if @view.name == 'pages-welcome_add_to_slack_new'
    return false if @view.name == 'pages-about'
    true
  end

  def show_header
    return false if @view.name == 'pages-add_to_slack'
    return false if @view.name == 'pages-welcome_add_to_slack_new'
    return false if @view.name == 'pages-about'
    true
  end

  def show_footer
    return false if @view.name == 'pages-add_to_slack'
    return false if @view.name == 'pages-welcome_add_to_slack_new'
    return false if @view.name == 'pages-about'
    true
  end

  def show_main
    return false if @view.name == 'pages-add_to_slack'
    return false if @view.name == 'pages-welcome_add_to_slack_new'
    true
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
