#
class Member < ActiveRecord::Base
  belongs_to :team
  has_many :list_items, dependent: :destroy
end
