class AddsHasCriteria < ActiveRecord::Migration
  def up
    add_column :quests, :number_of_criteria, :integer, :null => false, :default => 0

    ActiveRecord::AccessControl.as(User.admin) do
      Quest.all.each do |quest|
        #quest.update_number_of_criteria
        quest.save!
      end
    end
  end

  def down
    remove_column :quests, :number_of_criteria
  end
end
