#
class RegisteredTeam < ActiveRecord::Base
  belongs_to :user

  # CLASS and Instance methods that extend the User ActiveRecord class via
  # /models/concerns files. And add useful helper routines and to put biz logic
  # in the model and not in controllers.
  include RegisteredTeamExtensions # /models/concerns/registered_team_extensions.rb
end
