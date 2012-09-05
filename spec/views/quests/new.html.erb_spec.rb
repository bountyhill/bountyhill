require 'spec_helper'

describe "quests/new" do
  before(:each) do
    assign(:quest, stub_model(Quest).as_new_record)
  end

  it "renders new quest form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => quests_path, :method => "post" do
    end
  end
end
