#
class User < ActiveRecord::Base
  has_many :teams, dependent: :destroy
  has_many :omniauth_providers, dependent: :destroy

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable,
  # :recoverable, :trackable
  devise :database_authenticatable, :registerable,
         :confirmable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:github, :slack, :google_oauth2]

  validates :name, length: { minimum: 1, maximum: 100 }, presence: true

  # CLASS and Instance methods that extend the User ActiveRecord class via
  # /models/concerns files. And add useful helper routines and to put biz logic
  # in the model and not in controllers.
  include UserExtensions # /models/concerns/user_extensions.rb
end
