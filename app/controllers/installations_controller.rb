class InstallationsController < ApplicationController
  before_action :make_view_helper

  def index
    installations = Installation.installations
    per_page = 1 if @view.url_params[:options] == 'info'
    per_page = 2 unless @view.url_params[:options] == 'info'
    @view.locals = { installations: installations.paginate(page: params[:page],
                                                           per_page: per_page),
                     total_installations: installations.length,
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
