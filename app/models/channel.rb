#
class Channel < ActiveRecord::Base
  belongs_to :team
  belongs_to :member
  has_many :list_items, dependent: :destroy
end
