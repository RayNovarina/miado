#
class Member < ActiveRecord::Base
  belongs_to :team
  
  # CLASS and Instance methods that extend the User ActiveRecord class via
  # /models/concerns files. And add useful helper routines and to put biz logic
  # in the model and not in controllers.
  include MemberExtensions # /models/concerns/member_extensions.rb
end
