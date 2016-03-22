#
class Users::ConfirmationsController < Devise::ConfirmationsController
  before_action :make_view_helper

  # GET /resource/confirmation/new
  # def new
  # end

  # POST /resource/confirmation
  # def create
  # end

  # GET /resource/confirmation?confirmation_token=abcdef
  # def show
  # end

  # protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # def after_confirmation_path_for(resource_name)
  #   super(resource_name)
  # end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, resource || User.new)
  end
end
