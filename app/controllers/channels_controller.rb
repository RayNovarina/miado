#
class ChannelsController < ApplicationController
  before_action :make_view_helper
  before_filter :authenticate_user!

  # A frequent practice is to place the standard CRUD actions in each controller
  # in the following order:
  #   index, show, new, edit, create, update and destroy.
  #
  # Note: we get here via /channels to display all channels in system (admin link)
  #                    or /user/:user_id/channels for "My channels" link
  def index
    @view.channels = @view.url_params.key?('user_id') \
      ? Channel.where('user_id = ?', current_user.id) \
      : Channel.all
    # authorize @view.channels
    # Response: Controller will forward_to
    #           /views/channels/index.html.erb with @view
  end

  def show
    @view.channel = Channel.find(params[:id])
    authorize @view.channel
    # Response: Controller will forward_to
    #           /views/channels/show.html.erb with @view
  end

  def destroy
    # Note: should tell slack to remove channel from team?
    @view.channel = Channel.find(params[:id])
    authorize @view.channel
    # Response: redirect to or forward_to to a view.
    if @view.channel.destroy
      flash[:notice] = "\"#{@view.channel.name}\" was deleted successfully."
      # Display list of channels for this user.
      redirect_to action: :index
    else
      flash.now[:alert] = 'There was an error deleting this channel.'
      render :show
    end
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, Channel.new)
  end
end
