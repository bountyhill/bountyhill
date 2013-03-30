require 'spec_helper'

feature "Identities", :js => true, :driver => :rack_test do
  
  scenario "signin page" do
    visit '/signin'
    page.should have_selector('h3', :text => I18n.t("identity.form.title"))
    page.should have_selector('h4', :text => I18n.t("identity/email.form.title"))
    page.should have_selector('h4', :text => I18n.t("identity/twitter.form.title"))
    page.should have_selector('h4', :text => I18n.t("identity/new.form.title"))
  end
  
end
