# encoding: UTF-8

class AddUserInformation < ActiveRecord::Migration
  def change
    add_column :users, "serialized", :text
    add_column :users, "deleted_at", :datetime
  end
end
