class InstallationsController < ApplicationController
  before_action :make_view_helper

  def index
    installations = Installation.installations
    @view.locals = { installations: installations,
                     teams: Installation.teams,
                     bot_info: Channel.bot_info(installations: installations)
                   }
  end

  def show
    @view.locals = { installation: Installation.find(params[:id]) }
  end

  def destroy
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
