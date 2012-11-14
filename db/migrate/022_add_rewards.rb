class AddRewards < ActiveRecord::Migration
  def change
    add_column "users", "badges", :text
    add_column "users", "points", :integer, :null => false, :default => 0

    add_index "users", "points"
  end
end
