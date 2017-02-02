class InstallationsController < ApplicationController
  before_action :make_view_helper

  def index
    sort_by_param = params[:sortby] || 'install_date'
    installations = Installation.installations(sort_by: sort_by_param)
    paginate_page_param_name = 'page'
    paginate_per_page = 1 if @view.url_params[:options] == 'info'
    paginate_per_page = 10 unless @view.url_params[:options] == 'info'
    @view.locals = { paginate_page_param_name: paginate_page_param_name,
                     paginate_per_page: paginate_per_page,
                     installations_paginated: installations.paginate(page: params[paginate_page_param_name],
                                                                     per_page: paginate_per_page),
                     num_installations: installations.length,
                     num_teams: Installation.num_teams,
                     bot_info: Channel.bot_info(installation: installations.empty? ? nil : installations[0]),
                     sort_by_param: sort_by_param
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
