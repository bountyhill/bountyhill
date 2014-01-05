class CreateMessages < ActiveRecord::Migration
  def change
    create_table "messages", :force => true do |t|
      t.integer   "sender_id",      :null => false
      t.integer   "receiver_id",    :null => false
      t.integer   "reference_id",   :null => false
      t.string    "reference_type", :null => false
      t.string    "subject",        :null => false
      t.text      "body",           :null => false
      t.datetime  "created_at",     :null => false
      t.datetime  "updated_at",     :null => false
    end
    
    add_index :messages, :sender_id
    add_index :messages, [:reference_id, :reference_type]
  end
end
