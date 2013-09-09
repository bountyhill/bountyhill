require 'spec_helper'

describe "User pages" do
  describe "profile" do
    let(:user) { Factory(:email_identity).user }
    before { visit user_path(user) }

    describe "page" do
      it {
        # should have_selector('h1',    text: user.name) 
        # should have_selector('title', text: I18n.t(:profile)) 
      }
    end
  end
end
