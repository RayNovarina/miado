#
class Member < ActiveRecord::Base
  belongs_to :registered_team
  has_many :channels, dependent: :destroy
end
