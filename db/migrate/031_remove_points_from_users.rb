# encoding: UTF-8

class RemovePointsFromUsers < ActiveRecord::Migration
  def up
    remove_column "users", "points"
  end

  def down
    add_column "users", "points", :integer, :null => false, :default => 0
    add_index "users", "points"
  end
end
