#
class ItemsController < ApplicationController
  before_action :make_view_helper
  before_filter :authenticate_user!

  # A frequent practice is to place the standard CRUD actions in each controller
  # in the following order:
  #   index, show, new, edit, create, update and destroy.
  #
  def index
    @view.items = ListItem.all
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
