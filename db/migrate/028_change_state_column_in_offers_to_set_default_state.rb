class ChangeStateColumnInOffersToSetDefaultState < ActiveRecord::Migration
  def up
    change_column :offers, :state, :string, :default => "active"
  end

  def down
    change_column :offers, :state, :string, :default => nil
  end
end
