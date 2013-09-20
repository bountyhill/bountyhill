# encoding: UTF-8

class AddCommercialFlagToIdentities < ActiveRecord::Migration
  def change
    add_column :identities, :commercial, :boolean
  end
end
