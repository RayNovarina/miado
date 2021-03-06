#
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  #
  require_relative '../api/slack/slash/concerns/commands' # method for each slack command
  require_relative '../api/slack/slash/concerns/helpers' # various utility methods/controller lib.

  before_action :make_view_helper
  # Implemented per: https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview
  # Note: we get here here when the user has finished with the oauth provider's
  # permission page and the oauth provider uses the "redirect uri" we set when
  # we configured our app. I.e. Slack redirects to /users/auth/slack/callback
  # which is mapped to the following route:
  # Rails route path: "user_omniauth_callback"
  #  url: POST /users/auth/:action/callback(.:format)
  #  Rails controller#action:
  #    users/omniauth_callbacks#(?-mix:github|slack|google_oauth2)
  # Sooo.... /users/auth/slack/callback -->
  #   OmniauthCallbacksController.slack method below.

  # Flow is generally the same for all. But customize as needed here.
  def slack
    omniauth_callback
  end

  def github
    omniauth_callback
  end

  def google_oauth2
    omniauth_callback
  end

  def failure
    # cancel button clicked.
    # No HTTP_REFERER was set in the request to this action,
    # so redirect_to :back could not be called successfully. If this is a test,
    # make sure to specify request.env["HTTP_REFERER"].
    # redirect_to :back
    redirect_to :root
  end

  private

  def omniauth_callback
    # IF we allow multiple oath login providers, i.e. login with GitHub and
    # Gmail, then we need a OmniAuthProviders model with provider, uid and
    # auth_token fields. To find the user, first query the Providers model for
    # the provider/uid.
    # Note: we are using omniauth-slack at
    #       https://github.com/kmrshntr/omniauth-slack for a ruby oauth lib.
    #       It stores oauth info in the environment, which is accessed via
    #       request.env
    #---------------------------------------------------------------------------
    # Note: We get here from an oauth callback due to a sign_up or a sign_in.
    #---------------------------------------------------------------------------
    sign_up_from_omniauth if request.env['omniauth.params']['state'] == 'sign_up'
    sign_in_from_omniauth if request.env['omniauth.params']['state'] == 'sign_in'
    #
    # Note: sign_in_and_redirect method is at:
    # .rvm/gems/ruby-2.3.0/gems/devise-3.5.6/lib/devise/controllers/helpers.rb
    # It will finally redirect via "redirect_to after_sign_in_path_for(User)"
    # which we handle in our /controllers/application_controller
    # "after_sign_in_path_for(_resource_or_scope)" method which finally
    # redirects a welcome aboard landing page.
    unless request.env['omniauth.params']['state'] == 'sign_up' && request.env['omniauth.auth'].provider == 'slack'
      sign_in_and_redirect @view.user, event: :authentication
      set_flash_message(:notice, :success, kind: request.env['omniauth.auth'].provider.capitalize) if is_navigational_format?
    end
    if request.env['omniauth.params']['state'] == 'sign_up' && request.env['omniauth.auth'].provider == 'slack'
      set_flash_message(:notice, :success, kind: request.env['omniauth.auth'].provider.capitalize)
      # omniauth_landing_page => "/welcome/add_to_slack_new?team_id=T0VN565N0"
      redirect_to omniauth_landing_page
    end
  end

  def sign_up_from_omniauth
    if request.env['omniauth.auth'].provider == 'slack'
      # NOTE: hack to not create so much overhead for slack installs.
      @view.user = User.where(email: 'admin@example.com')
      # If reinstall, update changed install info such as tokens.
      @view.installation = Installation.update_from_or_create_from(source: :omniauth_callback, request: request)
      @view.member = Member.update_from_or_create_from(source: :installation, installation: @view.installation)
      # Now that member has a taskbot installed, send it an updated list.
      @view.channel = Channel.find_or_create_taskbot_channel_from(source: :installation, installation: @view.installation)
      sign_up_update_taskbot_channel
    end
  end

  def sign_up_update_taskbot_channel
    def_cmds = sign_up_taskbot_new_user if ListItem.all.empty?
    def_cmds = sign_up_taskbot_returning_user unless ListItem.all.empty?
    # NOTE: a new Thread may be generated to run these deferred commands.
    after_action_deferred_logic(def_cmds)
  end

  #   Simulate an add task slash command so that our deferred logic posts a
  #   current list to the taskbot channel.
  # Returns: def_cmds[]
  def sign_up_taskbot_returning_user
    p_hash = sign_up_taskbot_common_phash.merge!(
      expedite_deferred_cmd: true,
      func: :add)
    generate_after_action_cmds(parsed_hash: p_hash)
  end

  # Send welcome aboard msg to installing user's Taskbot dm channel.
  # Returns: def_cmds[]
  def sign_up_taskbot_new_user
    p_hash = sign_up_taskbot_common_phash.merge!(
      expedite_deferred_cmd: true,
      func: :onboarding)
    generate_after_action_cmds(parsed_hash: p_hash)
  end

  # Returns: p_hash{} with base fields filled in.
  def sign_up_taskbot_common_phash
    make_parse_hash.merge!(
      ccb: @view.channel,
      tcb: @view.channel,
      mcb: @view.member,
      assigned_member_id: @view.member.slack_user_id,
      assigned_member_name: @view.member.slack_user_name,
      url_params: params.merge!(
        team_id: @view.member.slack_team_id,
        text: '',
        user_id: @view.member.slack_user_id,
        user_name: @view.member.slack_user_name))
  end

  # Note: The provider, user or team can already be in our db due to other
  #       ways to add em. i.e. signin/up via manual form, user tries signin/up
  #       via multiple signin with buttons.
  # Returns: @view.user = nil means not a known user.
  def sign_in_from_omniauth
    @view.provider = OmniauthProvider.find_or_create_from(:omniauth_callback, request.env)
    unless @view.provider.user.nil?
      @view.user = User.find_from(:omniauth_provider, @view.provider)
      @view.team = Team.find_from(:omniauth_provider, @view.provider)
      return
    end
    # We have not authenticated with this oauth server for the oauth user
    # before. But we may have already created a user via a email/pwd sign-up.

    # Case: # User signing in with GitHub/Slack but has not setup account yet.
    return if (@view.user = User.where(email: @view.provider.uid_email.downcase).first).nil?

    # We have the user, link it to the new OmniauthProvider.
    @view.provider.user = @view.user
    @view.provider.save!
    # And link the OmniauthProvider to the user.
    @view.user.omniauth_providers << @view.provider
    @view.user.save!
    @view.team = Team.find_from(:omniauth_provider, @view.provider)
  end

  def make_view_helper
    @view = ApplicationHelper::View.new(self, resource || User.new)
  end

  #
  # You should also create an action method in this controller like this:
  # def twitter
  # end

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end
