#
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :make_view_helper

  def index
    per_page = 1
    @view.locals = { users_paginated: User.paginate(page: params[:page], per_page: per_page),
                     page: params[:page] || '1',
                     per_page: per_page,
                     num_users: User.count,
                     installations: Installation.installations,
                     teams: Installation.teams
                   }
  end

  def show
    @view.locals = { user: User.find(params[:id]) }
  end

  def settings
  end

  # Note: We get here via Admin Dashboard. Devise has cancel function in the
  # registrations edit page.
  def destroy
    @view.user = User.find(params[:id])
    authorize @view.user
    # Response: redirect to or forward_to to a view.
    if @view.user.destroy
      flash[:notice] = "\"#{@view.user.name}\" was deleted successfully."
      # Display list of users.
      redirect_to users_path
    else
      flash.now[:alert] = 'There was an error deleting this User.'
      render :show
    end
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
