class InstallationsController < ApplicationController
  before_action :make_view_helper

  def index
    installations = Installation.installations
    per_page = 10 # if @view.url_params[:options] == 'info'
    # per_page = 2 unless @view.url_params[:options] == 'info'
    @view.locals = { installations_paginated: installations.paginate(page: params[:page],
                                                                     per_page: per_page),
                     page: params[:page] || '1',
                     per_page: per_page,
                     num_installations: installations.length,
                     num_teams: Installation.num_teams,
                     bot_info: Channel.bot_info(installation: installations.empty? ? nil : installations[0])
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
