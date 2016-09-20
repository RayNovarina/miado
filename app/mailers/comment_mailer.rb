#
class CommentMailer < ApplicationMailer
  default from: 'admin@miado.net'
  default to: 'RNova94037@gmail.com'
  default cc: 'Dawn.Novarina@wemeus.com'

  def new_comment(view, submitted_comment)
    @view = view
    @comment = submitted_comment
    mail(subject: "#{Rails.env == 'staging' ? 'QA-' : ''}New comment from #{submitted_comment.name} at " \
                  "#{submitted_comment.email}")
  end
end
