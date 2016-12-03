#
class Installation < ActiveRecord::Base
  belongs_to :user
  default_scope { order('slack_team_id ASC, created_at DESC') }

  # CLASS and Instance methods that extend the User ActiveRecord class via
  # /models/concerns files. And add useful helper routines and to put biz logic
  # in the model and not in controllers.
  include InstallationExtensions # /models/concerns/installation_extensions.rb
end
