#
class InstallationController < ApplicationController
  before_action :make_view_helper
  before_filter :authenticate_user!

  # A frequent practice is to place the standard CRUD actions in each controller
  # in the following order:
  #   index, show, new, edit, create, update and destroy.
  #
  def index
    @view.installations = { installations: Installation.all }
    # authorize @view.installations
    # Response: Controller will forward_to
    #           /views/installations/index.html.erb with @view
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, Installation.new)
  end
end
