class RenameCategorySportsToServices < ActiveRecord::Migration
  def up
    Quest.update_all({ :category => 'services' }, { :category => 'sports' })
  end

  def down
    Quest.update_all({ :category => 'sports' }, { :category => 'services' })
  end
end
