#
# Methods in this file are only available to views.
#
module ApplicationHelper
  #
  class View
    attr_reader :id, :name, :controller, :model
    attr_accessor :locals, :signed_out_user, :user, :teams, :team, :provider,
                  :web_client, :rtm_client

    def initialize(controller, model)
      @id = object_id
      url_params = controller.params || []
      @name = "#{url_params[:controller]}-#{url_params[:action]}"
      @controller = controller
      @model = model
    end

    # If authentication system (i.e. Devise) active.
    # controller.is_a?(::DeviseController)
    def devise?
      !(defined? @controller.current_user).nil?
    end

    # If authorized roles (Pundit or Devise?).
    def roles?
      false # !(defined? User.new.roles).nil?
    end

    # Most devise helpers for views and controllers are found in sources at:
    #   gems/devise-3.5.6/lib/devise/controllers/helpers.rb
    def user_signed_in?
      # Note: user_signed_in? is a devise method visible to our controllers.
      #       Method defined at:
      # /gems/ruby-2.2.4/gems/devise-3.5.6/lib/devise/controllers/helpers.rb
      devise? ? @controller.user_signed_in? : true
    end

    def current_user
      # Note: current_user is a devise method visible to our controllers.
      #       Method defined at:
      # /gems/ruby-2.2.4/gems/devise-3.5.6/lib/devise/controllers/helpers.rb
      devise? ? @controller.current_user : User.new
    end

    # Get flash msgs from controller so we can override em.
    def flash_messages
      @controller.flash
    end

    # Let each controller decide where the back button goes.
    def back_path
      return :back if (defined? @controller.page_back_button_path).nil?
      @controller.page_back_button_path
    end

    def show_header?

    end

    def policy(arg1, arg2)
      return include_policy(arg2) if arg1 == :include
      true
    end

    private

    def include_policy(element)
      if element == :back_button
        !@controller.is_a?(::PagesController)
      elsif element == :header
        return true if (defined? @controller.show_header).nil?
        @controller.show_header
      elsif element == :footer
        return true if (defined? @controller.show_footer).nil?
        @controller.show_header
      else
        true
      end
    end
    #
  end # class View
end
