# encoding: UTF-8

class AddTitleToOffers < ActiveRecord::Migration
  def change
    add_column :offers, :title, :string
  end
end