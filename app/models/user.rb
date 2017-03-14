#
class User < ActiveRecord::Base
  has_many :teams, dependent: :destroy
  has_many :omniauth_providers, dependent: :destroy

  before_save { self.role ||= :member }

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable,
  # :recoverable, :trackable
  # :omniauthable, omniauth_providers: [:github, :slack, :google_oauth2]
  devise :database_authenticatable, :registerable,
         :confirmable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:github, :slack]

  validates :name, length: { minimum: 1, maximum: 100 }, presence: true

  enum role: [:member, :admin]

  default_scope { order('name ASC, created_at DESC') }

  # CLASS and Instance methods that extend the User ActiveRecord class via
  # /models/concerns files. And add useful helper routines and to put biz logic
  # in the model and not in controllers.
  include UserExtensions # /models/concerns/user_extensions.rb
end
