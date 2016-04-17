require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe 'anonymous user' do
    before :each do
      # This simulates an anonymous user
      login_with nil
    end

    it 'should be redirected to signin' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET #index' do
    it 'should let a user see all the posts' do
      login_with create(:user)
      get :index
      expect(response).to render_template(:index)
    end
  end
  # describe 'GET #index' do
  #  it 'returns http success' do
  #    get :index
  #    expect(response).to have_http_status(:success)
  #  end
  # end

  # describe "GET #show" do
  #  it "returns http success" do
  #    get :show
  #    expect(response).to have_http_status(:success)
  #  end
  # end

  # describe "GET #settings" do
  #  it "returns http success" do
  #    get :settings
  #    expect(response).to have_http_status(:success)
  #  end
  # end
end
