# encoding: UTF-8

class AddLocationAndCriteria < ActiveRecord::Migration
  def up
    add_column :quests, :location, :string
    add_column :quests, :serialized, :text

    rename_column :identities, :options, :serialized
  end

  def down
    rename_column :identities, :serialized, :options

    remove_column :quests, :location, :serialized
  end
end
