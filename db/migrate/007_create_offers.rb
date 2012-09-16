class CreateOffers < ActiveRecord::Migration
  def change
    create_table "offers", :force => true do |t|
      t.text     "description",     :null => false
      t.integer  "owner_id",        :null => false
      t.integer  "quest_id",        :null => false
      t.integer  "compliance",      :null => false
      t.datetime "created_at",      :null => false
      t.datetime "updated_at",      :null => false
      t.text     "image"
      t.string   "location"
      t.text     "serialized"
    end
    
    add_index :offers, :owner_id
    add_index :offers, :quest_id
  end
end
