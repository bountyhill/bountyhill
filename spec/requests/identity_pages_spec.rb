require 'spec_helper'

describe "Identity pages" do

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
      it "should not create identity" do
        expect { click_button I18n.t(:sign_up) }.not_to change(Identity, :count)  
      end

    end

    describe "with valid information" do
      let(:email) { 'foo@bar.net' }

      before do
        fill_in Identity.human_attribute_name(:name),                   :with => "Foo Bar"
        fill_in Identity.human_attribute_name(:email),                  :with => email
        fill_in Identity.human_attribute_name(:password),               :with => "foobar"
        fill_in Identity.human_attribute_name(:password_confirmation),  :with => "foobar"
      end

      it "should create identity" do
        expect { click_button I18n.t(:sign_up) }.to change(Identity, :count)  
      end

      describe "after creating a identity" do
        before { click_button I18n.t(:sign_up) }
        let(:identity) { Identity.find_by_email(email) }

        it { should have_selector('h1', text: identity.name) }
        it { should have_selector('div.alert.alert-success', text: I18n.t("signup.message.success")) }

        describe "after saving the identity" do
          it { should have_link(I18n.t(:sign_out)) }
        end
      end
    end
  end

  describe "profile" do
    let(:identity) { FactoryGirl.create(:identity) }
    before { visit identity_path(identity) }

    describe "page" do
      it { should have_selector('h1',    text: identity.name) }
      it { should have_selector('title', text: I18n.t(:profile)) }
    end
  end
end