require 'rails_helper'

RSpec.describe User, type: :model do
  # user factory method to create user.
  let(:user) { FactoryGirl.create(:user) }

  describe 'attributes' do
    it 'should respond to name' do
      expect(user).to respond_to(:name)
    end

    it 'should respond to email' do
      expect(user).to respond_to(:email)
    end
  end
end
