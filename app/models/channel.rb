#
class Channel < ActiveRecord::Base
  has_many :list_items, dependent: :destroy
  default_scope { order('updated_at ASC') }

  # CLASS and Instance methods that extend the User ActiveRecord class via
  # /models/concerns files. And add useful helper routines and to put biz logic
  # in the model and not in controllers.
  include ChannelExtensions # /models/concerns/channel_extensions.rb
end
