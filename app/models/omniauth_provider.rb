#
class OmniauthProvider < ActiveRecord::Base
  belongs_to :user
end
