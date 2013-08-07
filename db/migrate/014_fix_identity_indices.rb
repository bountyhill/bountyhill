# encoding: UTF-8

class FixIdentityIndices < ActiveRecord::Migration
  def up
    remove_index "identities", ["email"]
    remove_index "identities", ["name", "type"]

    add_index "identities", ["email", "type"], :unique => true
    add_index "identities", ["name", "type"]
  end

  def down
  end
end
