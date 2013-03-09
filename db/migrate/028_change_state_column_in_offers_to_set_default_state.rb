class ChangeStateColumnInOffersToSetDefaultState < ActiveRecord::Migration
  def up
    change_column :offers, :state, :string, :default => "offered"
  end

  def down
    change_column :offers, :state, :string, :default => nil
  end
end
