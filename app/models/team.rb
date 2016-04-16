#
class Team < ActiveRecord::Base
  belongs_to :user
  has_many :members, dependent: :destroy

  # CLASS and Instance methods that extend the User ActiveRecord class via
  # /models/concerns files. And add useful helper routines and to put biz logic
  # in the model and not in controllers.
  include TeamExtensions # /models/concerns/team_extensions.rb
end
