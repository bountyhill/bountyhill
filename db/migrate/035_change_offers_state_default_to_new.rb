# encoding: UTF-8

class ChangeOffersStateDefaultToNew < ActiveRecord::Migration
  def up
    change_column :offers, :state, :string, :default => "new"
  end

  def down
    change_column :offers, :state, :string, :default => "active"
  end
end
