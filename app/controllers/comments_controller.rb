#
class CommentsController < ApplicationController
  before_action :make_view_helper
  skip_before_action :verify_authenticity_token

  def create
    @submitted_comment = Comment.new(comment_params_whitelist)
    if @submitted_comment.valid?
      CommentMailer.new_comment(@view, @submitted_comment).deliver_now
    end
    redirect_to :root
  end

  private

  def comment_params_whitelist
    params.permit(:name, :email, :body)
  end

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
