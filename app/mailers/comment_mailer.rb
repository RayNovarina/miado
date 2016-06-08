#
class CommentMailer < ApplicationMailer
  default from: 'admin@miado.net'
  default to: 'RNova94037@gmail.com'
  default to: 'Dawn.Novarina@wemeus.com'

  def new_comment(submitted_comment)
    @comment = submitted_comment
    mail(subject: "New comment from #{submitted_comment.name} at " \
                  "#{submitted_comment.email}")
  end
end
