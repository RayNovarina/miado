#
class RegisteredTeam < ActiveRecord::Base
  belongs_to :user
end
