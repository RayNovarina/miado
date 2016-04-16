class ListItem < ActiveRecord::Base
  belongs_to :channel
  belongs_to :member
end
