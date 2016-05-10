#
class OmniauthProvidersController < ApplicationController
  before_action :make_view_helper
  before_filter :authenticate_user!

  # A frequent practice is to place the standard CRUD actions in each controller
  # in the following order:
  #   index, show, new, edit, create, update and destroy.
  #
  def index
    @view.providers = OmniauthProvider.all
    # authorize @view.providers
    # Response: Controller will forward_to
    #           /views/omniauth_providers/index.html.erb with @view
  end

  def show
    @view.provider = OmniauthProvider.find(params[:id])
    authorize @view.provider
    # Response: Controller will forward_to
    #           /views/omniauth_providers/show.html.erb with @view
  end

  def destroy
    @view.provider = OmniauthProvider.find(params[:id])
    authorize @view.provider
    # Response: redirect to or forward_to to a view.
    if @view.provider.destroy
      flash[:notice] = "\"#{@view.provider.name}\" was deleted successfully."
      # Display list of providers for this user.
      redirect_to action: :index
    else
      flash.now[:alert] = 'There was an error deleting this OmniauthProvider.'
      render :show
    end
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, OmniauthProvider.new)
  end
end
