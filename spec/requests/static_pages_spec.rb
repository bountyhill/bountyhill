require 'spec_helper'

describe "Static pages" do
  subject { page }

  describe "visit root page" do
    before { visit root_path }
    it { should have_selector('title',  text: "bountyhill") }
    it { should have_selector('h1',     text: I18n.t("home")) }
  end

  %w(about help privacy terms).each do |static_page|
    describe "visit #{static_page} page" do
      before { visit send("#{static_page}_path") }
      it { should have_selector('title', text: "bountyhill | #{I18n.t(static_page)}") }
      it { should have_selector('h1',    text: I18n.t(static_page)) }
    end
  end

end
