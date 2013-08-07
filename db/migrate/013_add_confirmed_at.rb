# encoding: UTF-8

class AddConfirmedAt < ActiveRecord::Migration
  def change
    add_column :identities, :confirmed_at, :datetime
  end
end
