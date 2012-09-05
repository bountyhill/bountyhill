class AddImageUrlToQuests < ActiveRecord::Migration
  def change
    add_column :quests, :image_url, :text
  end
end
