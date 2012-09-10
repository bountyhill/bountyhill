class AddQuestColumns < ActiveRecord::Migration
  def up
    add_column :quests, :visibility, :string
    add_index :quests, :visibility

    rename_column :quests, :user_id, :owner_id
  end

  def down
    rename_column :quests, :owner_id, :user_id
    remove_column :quests, :visibility
  end
end
