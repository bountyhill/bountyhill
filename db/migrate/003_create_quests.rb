class CreateQuests < ActiveRecord::Migration
  def change
    create_table :quests do |t|
      t.integer     :bounty_in_cents

      t.datetime    :started_at
      t.datetime    :ends_at
      
      t.timestamps  
    end
  end
end
