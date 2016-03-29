#
class MessagesController < ApplicationController
  before_action :make_view_helper

  def index
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, resource || User.new)
  end
end
