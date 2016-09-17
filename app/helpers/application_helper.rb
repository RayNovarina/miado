#
# Methods in this file are only available to views.
#
module ApplicationHelper
  #
  class View
    attr_reader :id, :name, :controller, :model, :url_params
    attr_accessor :locals, :signed_out_user, :users, :user, :teams, :team,
                  :providers, :provider, :web_client, :rtm_client,
                  :members, :member, :channels, :channel, :items, :item,
                  :exception, :installations, :installation

    def initialize(controller, model)
      @id = object_id
      @url_params = controller.params || []
      @name = "#{url_params[:controller]}-#{url_params[:action]}"
      @controller = controller
      @model = model
      @user = current_user
      @locals = {}
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

    def admin_user?
      current_user.admin?
    end

    def running_on_qa?
      @controller.request.domain == 'qa-miado.herokuapp.com'
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

    def policy(arg1, arg2)
      return include_policy(arg2) if arg1 == :include
      true
    end

    private

    def include_policy(element)
      if element == :back_button
        !@controller.is_a?(::PagesController)
      elsif element == :asset_pipeline
        return true if (defined? @controller.use_asset_pipeline).nil?
        @controller.use_asset_pipeline
      elsif element == :header
        return true if (defined? @controller.show_header).nil?
        @controller.show_header
      elsif element == :footer
        return true if (defined? @controller.show_footer).nil?
        @controller.show_header
      elsif element == :main
        return true if (defined? @controller.show_main).nil?
        @controller.show_main
      else
        true
      end
    end
    #
  end # class View
end
