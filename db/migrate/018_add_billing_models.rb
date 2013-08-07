# encoding: UTF-8

class AddBillingModels < ActiveRecord::Migration
  def change
    create_table "accounts", :force => true do |t|
      t.integer  "owner_id"
    end

    add_index "accounts", ["owner_id"], :unique => true

    create_table "liabilities", :force => true do |t|
      t.integer   "account_id",       :null => false
      t.integer   "other_account_id", :null => false
      t.integer   "amount_in_cents",  :null => false, :default => 0
      t.string    "reference_type",   :null => false
      t.integer   "reference_id",     :null => false
    end

    add_index "liabilities", ["account_id"]
  end
end
