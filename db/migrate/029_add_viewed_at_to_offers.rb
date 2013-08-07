# encoding: UTF-8

class AddViewedAtToOffers < ActiveRecord::Migration
  def change
    add_column :offers, :viewed_at, :datetime
  end
end
