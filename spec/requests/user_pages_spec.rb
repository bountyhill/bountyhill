require 'spec_helper'

describe "User pages" do

  subject { page }

  describe "signup" do
    before { visit signup_path }

    describe "page" do
      it { should have_selector('h1',    text: I18n.t(:sign_up)) }
      it { should have_selector('title', text: I18n.t(:sign_up)) }
    end

    describe "with invalid information" do
      before { click_button I18n.t(:sign_up) }      
      it { should have_content('error') }
      it { should have_selector('div.alert.alert-error', text: I18n.t("signup.message.error")) }
      it "should not create user" do
        expect { click_button I18n.t(:sign_up) }.not_to change(User, :count)  
      end

    end

    describe "with valid information" do
      let(:email) { 'foo@bar.net' }

      before do
        fill_in User.human_attribute_name(:name),                   :with => "Foo Bar"
        fill_in User.human_attribute_name(:email),                  :with => email
        fill_in User.human_attribute_name(:password),               :with => "foobar"
        fill_in User.human_attribute_name(:password_confirmation),  :with => "foobar"
      end

      it "should create user" do
        expect { click_button I18n.t(:sign_up) }.to change(User, :count)  
      end

      describe "after creating a user" do
        before { click_button I18n.t(:sign_up) }
        let(:user) { User.find_by_email(email) }

        it { should have_selector('h1', text: user.name) }
        it { should have_selector('div.alert.alert-success', text: I18n.t("signup.message.success")) }

        describe "after saving the user" do
          it { should have_link(I18n.t(:sign_out)) }
        end
      end
    end
  end

  describe "profile" do
    let(:user) { FactoryGirl.create(:user) }
    before { visit user_path(user) }

    describe "page" do
      it { should have_selector('h1',    text: user.name) }
      it { should have_selector('title', text: I18n.t(:profile)) }
    end
  end
end