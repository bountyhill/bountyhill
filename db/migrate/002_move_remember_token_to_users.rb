# encoding: UTF-8

class MoveRememberTokenToUsers < ActiveRecord::Migration
  def up
    remove_column "identities", "remember_token"
    add_column "users", "remember_token", :string

    add_index "users", "remember_token"
  end

  def down
    add_column "identities", "remember_token", :string
    remove_column "users", "remember_token"

    remove_index "users", "remember_token"
  end
end
