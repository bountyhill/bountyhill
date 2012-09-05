class AddImageUrlToQuests < ActiveRecord::Migration
  def change
    add_column :quests, :image, :text
  end
end
