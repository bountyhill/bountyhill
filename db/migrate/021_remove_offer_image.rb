class RemoveOfferImage < ActiveRecord::Migration
  def up
    remove_column :offers, :image
  end

  def down
    add_column :offers, :image, :text
  end
end
