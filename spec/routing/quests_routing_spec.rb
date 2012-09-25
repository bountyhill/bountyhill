require "spec_helper"

describe QuestsController do
  describe "routing" do

    it "routes to #index" do
      get("/quests").should route_to("quests#index")
    end

    it "routes to #new" do
      get("/quests/new").should route_to("quests#new")
    end

    it "routes to #show" do
      get("/quests/1").should route_to("quests#show", :id => "1")
    end

    it "routes to #edit" do
      get("/quests/1/edit").should route_to("quests#edit", :id => "1")
    end

    it "routes to #create" do
      post("/quests").should route_to("quests#create")
    end

    it "routes to #update" do
      put("/quests/1").should route_to("quests#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/quests/1").should route_to("quests#destroy", :id => "1")
    end

  end
end
