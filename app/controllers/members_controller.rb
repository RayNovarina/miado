#
class MembersController < ApplicationController
  before_action :make_view_helper
  before_filter :authenticate_user!

  # A frequent practice is to place the standard CRUD actions in each controller
  # in the following order:
  #   index, show, new, edit, create, update and destroy.
  #
  # Note: we get here via /members to display all members in system (admin link)
  #                    or /user/:user_id/members for "My members" link
  def index
    @view.members = @view.url_params.key?('user_id') \
      ? Member.where('user_id = ?', current_user.id) \
      : Member.all
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
