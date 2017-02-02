#
class ItemsController < ApplicationController
  before_action :make_view_helper
  before_filter :authenticate_user!

  # A frequent practice is to place the standard CRUD actions in each controller
  # in the following order:
  #   index, show, new, edit, create, update and destroy.
  #
  def index
    # team_channels = Installation.team_channels
    # HACK: use installations instead of teams for reporting. Teams dont get
    # sorted in the same order as the installations report. We want both to
    # show most recently installed team first. Just easier to use
    # Installation.installations instead of Installation.teams.
    sort_by_param = params[:sortby] || 'install_date'
    @view.teams = Installation.installations(sort_by: sort_by_param)
    paginate_per_page = 1
    paginate_page_param_name = 'team_page'
    @view.locals = { paginate_page_param_name: paginate_page_param_name,
                     paginate_per_page: paginate_per_page,
                     teams_paginated: @view.teams.paginate(page: params[paginate_page_param_name],
                                                           per_page: paginate_per_page),
                     num_items: ListItem.count,
                     num_channels: Channel.count,
                     num_teams: @view.teams.length,
                     sort_by_param: sort_by_param
                   }
    # authorize @view.items
    # Response: Controller will forward_to
    #           /views/items/index.html.erb with @view
  end

  def show
    @view.item = ListItem.find(params[:id])
    authorize @view.item
    # Response: Controller will forward_to
    #           /views/items/show.html.erb with @view
  end

  def destroy
    # Note: should tell slack to remove item from team?
    @view.item = ListItem.find(params[:id])
    authorize @view.item
    # Response: redirect to or forward_to to a view.
    if @view.item.destroy
      flash[:notice] = "\"#{@view.item.description}\" was deleted successfully."
      # Display list of items for this channel.
      redirect_to action: :index
    else
      flash.now[:alert] = 'There was an error deleting this item.'
      render :show
    end
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, ListItem.new)
  end
end
