class CreateUsersAndIdentities < ActiveRecord::Migration
  def change
    create_table "identities", :force => true do |t|
      t.string   "name"
      t.string   "email"
      t.string   "password_digest"
      t.datetime "created_at",      :null => false
      t.datetime "updated_at",      :null => false
      t.string   "remember_token"
      t.string   "type"
      t.integer  "user_id"
      t.text     "options"
    end

    add_index "identities", ["email"], :unique => true
    add_index "identities", ["remember_token"]
    add_index "identities", ["user_id", "id", "type"], :unique => true

    create_table "users", :force => true do |t|
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end
  end
end
