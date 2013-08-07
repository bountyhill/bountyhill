# encoding: UTF-8

class CreateQuests < ActiveRecord::Migration
  def change
    create_table :quests do |t|
      t.string      :title, :null => false
      t.text        :description, :null => false
      
      t.integer     :bounty_in_cents, :null => false
      t.integer     :user_id

      t.datetime    :started_at
      t.datetime    :ends_at
      
      t.timestamps
    end
    
    add_index :quests, :user_id
  end
end
