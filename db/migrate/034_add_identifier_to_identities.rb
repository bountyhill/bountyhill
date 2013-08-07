# encoding: UTF-8

class AddIdentifierToIdentities < ActiveRecord::Migration
  def change
    add_column :identities, :identifier, :string
  end
end
