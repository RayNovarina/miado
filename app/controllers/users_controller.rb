#
class UsersController < ApplicationController
  before_action :make_view_helper

  def index
    @view.users = User.all
  end

  def show
    @view.user = User.find(params[:id])
  end

  def settings
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
