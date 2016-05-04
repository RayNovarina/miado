#
class ListItem < ActiveRecord::Base
  belongs_to :channel

  # CLASS and Instance methods that extend the User ActiveRecord class via
  # /models/concerns files. And add useful helper routines and to put biz logic
  # in the model and not in controllers.
  include ListItemExtensions # /models/concerns/member_extensions.rb
end
