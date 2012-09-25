require 'spec_helper'

describe "quests/edit" do
  before(:each) do
    @quest = assign(:quest, stub_model(Quest))
  end

  it "renders the edit quest form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => quests_path(@quest), :method => "post" do
    end
  end
end
