# encoding: UTF-8

class AddOffersState < ActiveRecord::Migration
  def up
    add_column "offers", "state", :string
    add_index "offers", "state"
  end

  def down
    remove_column "offers", "state"
  end
end
