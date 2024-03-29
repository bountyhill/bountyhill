require 'spec_helper'

describe "Authentication pages" do

  subject { page }

  describe "signin" do
    before { visit signin_path }

    describe "page" do
      it { should have_selector('h1',    text: I18n.t(:signin)) }
      it { should have_selector('title', text: I18n.t(:signin)) }
    end

    describe "with invalid information" do
      before { click_button I18n.t(:signin) }      
      it { should have_selector('h1',    text: I18n.t(:signin)) }
      it { should have_selector('title', text: I18n.t(:signin)) }
      it { should have_selector('div.alert.alert-error', text: I18n.t("signin.message.error")) }
      
      describe "after visiting another page" do
        before { click_link "bountyhill" }
        it { should_not have_selector('div.alert.alert-error') }
      end
    end

    describe "with valid information" do
      let(:identity) do Factory(:email_identity) end
      
      before do
        fill_in "Email",    with: identity.email
        fill_in "Password", with: identity.password
        click_button I18n.t(:signin)
      end

      it { should have_selector('title', text: I18n.t(:profile)) }
      it { should     have_link(I18n.t(:profile),   href: user_path(identity.user)) }
      it { should     have_link(I18n.t(:signout),  href: signout_path) }
      it { should_not have_link(I18n.t(:signin),   href: signin_path) }

      describe "followed by signout" do
        before { click_link I18n.t(:signout) }
        it { should have_link(I18n.t(:signin)) }
      end
    end
  end
end