require 'spec_helper'

describe "quests/index" do
  before(:each) do
    assign(:quests, [
      stub_model(Quest),
      stub_model(Quest)
    ])
  end

  it "renders a list of quests" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
