#
class PagesController < ApplicationController
  before_action :make_view_helper

  def welcome
  end

  def about
  end

  def welcome_new
  end

  def welcome_back
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
