class ForwardTransaction < ActiveRecord::Migration
  def up
    create_table :forwards do |t|
      t.integer :quest_id           # the id of the quest
      t.integer :sender_id          # the id of the sender
      t.text    :text               # the text of the forward
      t.text    :original_data      # the original data, serialized as JSON
      
      t.timestamps
    end
    
    add_index :forwards, :quest_id
    add_index :forwards, :sender_id
  end

  def down
    drop_table :forwards
  end
end
