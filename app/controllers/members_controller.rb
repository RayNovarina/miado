#
class MembersController < ApplicationController
  before_action :make_view_helper
  before_filter :authenticate_user!

  # A frequent practice is to place the standard CRUD actions in each controller
  # in the following order:
  #   index, show, new, edit, create, update and destroy.
  #
  def index
    # HACK: use installations instead of teams for reporting. Teams dont get
    # sorted in the same order as the installations report. We want both to
    # show most recently installed team first. Just easier to use
    # Installation.installations instead of Installation.teams.
    sort_by_param = params[:sortby] || 'install_date'
    teams = Installation.installations(sort_by: sort_by_param)
    paginate_per_page = 1
    paginate_page_param_name = 'page'
    @view.locals = { paginate_page_param_name: paginate_page_param_name,
                     paginate_per_page: paginate_per_page,
                     teams_paginated: teams.paginate(page: params[paginate_page_param_name],
                                                     per_page: paginate_per_page),
                     num_teams: teams.length,
                     num_members: Member.count,
                     sort_by_param: sort_by_param
                 }
    # authorize @view.members
    # Response: Controller will forward_to
    #           /views/members/index.html.erb with @view
  end

  def show
    @view.member = Member.find(params[:id])
    authorize @view.member
    # Response: Controller will forward_to
    #           /views/members/show.html.erb with @view
  end

  def destroy
    # Note: should tell slack to remove member from team?
    @view.member = Member.find(params[:id])
    authorize @view.member
    # Response: redirect to or forward_to to a view.
    if @view.member.destroy
      flash[:notice] = "\"#{@view.member.name}\" was deleted successfully."
      # Display list of members for this user.
      redirect_to action: :index
    else
      flash.now[:alert] = 'There was an error deleting this member.'
      render :show
    end
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, Member.new)
  end
end
