class CreateShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.integer :owner_id
      t.integer :quest_id
      t.string  :message
      t.text    :identities
      t.timestamps
    end
    add_index :shares, :owner_id
    add_index :shares, :quest_id
  end
end
