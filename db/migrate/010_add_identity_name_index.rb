# encoding: UTF-8

class AddIdentityNameIndex < ActiveRecord::Migration
  def change
    add_index "identities", ["name", "type"], :unique => true
  end
end
