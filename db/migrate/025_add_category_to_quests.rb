class AddCategoryToQuests < ActiveRecord::Migration
  def change
    add_column  :quests, :category, :text
    add_index   :quests, :category
  end
end