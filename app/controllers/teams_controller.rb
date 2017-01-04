#
class TeamsController < ApplicationController
  before_action :make_view_helper
  before_filter :authenticate_user!

  # A frequent practice is to place the standard CRUD actions in each controller
  # in the following order:
  #   index, show, new, edit, create, update and destroy.
  #
  # Note: we get here via /teams to display all teams in system (admin link)
  #                    or /user/:user_id/teams for "My Teams" link
  def index
    sort_by_param = params[:sortby] || 'install_date'
    teams = Installation.teams
    # HACK: use installations instead of teams for reporting. Teams dont get
    # sorted in the same order as the installations report. We want both to
    # show most recently installed team first. Just easier to use
    # Installation.installations instead of Installation.teams.
    installations = Installation.installations(sort_by: sort_by_param)
    paginate_per_page = 1
    paginate_page_param_name = 'page'
    @view.locals = { paginate_page_param_name: paginate_page_param_name,
                     paginate_per_page: paginate_per_page,
                     teams_paginated: installations.paginate(page: params[paginate_page_param_name],
                                                     per_page: paginate_per_page),
                     num_installations: installations.length,
                     num_teams: teams.length,
                     sort_by_param: sort_by_param
                 }
    # @view.teams = @view.url_params.key?('user_id') \
    #  ? Team.where('user_id = ?', current_user.id) \
    #  : Channel.teams
    # authorize @view.teams
    # Response: Controller will forward_to
    #           /views/teams/index.html.erb with @view
  end

  def show
    @view.locals = { team: Installation.find(params[:id]) }
    authorize @view.team
    # Response: Controller will forward_to
    #           /views/teams/show.html.erb with @view
  end

  def new
    authorize Team
    # Redirect to slack auth new team?
    # @view.team = Team.new
    # Response: Controller will forward_to
    #           /views/teams/new.html.erb with @view
    # Note: clicking on the form submit button will POST to create()
  end

  def destroy
    # Note: should tell slack to remove app from team?
    @view.team = Installation.find(params[:id])
    authorize @view.team
    # Response: redirect to or forward_to to a view.
    if @view.team.destroy
      flash[:notice] = "\"#{@view.team.name}\" was deleted successfully."
      # Display list of teams for this user.
      redirect_to action: :index
    else
      flash.now[:alert] = 'There was an error deleting this Team.'
      render :show
    end
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, Installation.new)
  end
end
