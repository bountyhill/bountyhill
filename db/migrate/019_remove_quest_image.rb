class RemoveQuestImage < ActiveRecord::Migration
  def up
    remove_column :quests, :image
  end

  def down
    add_column :quests, :image, :text
  end
end
