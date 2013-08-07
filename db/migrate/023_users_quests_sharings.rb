# encoding: UTF-8

class UsersQuestsSharings < ActiveRecord::Migration
  def up
    create_table :users_quests_sharings, :id => false do |t|
      t.integer "user_id", :null => false
      t.integer "quest_id", :null => false
    end
    
    add_index :users_quests_sharings, :user_id
    add_index :users_quests_sharings, [:quest_id, :user_id], :unique => true

    execute "ALTER TABLE users_quests_sharings ADD COLUMN created_at timestamp without time zone NOT NULL DEFAULT CURRENT_DATE"
  end

  def down
    drop_table :users_quests_sharings
  end
end
