class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      
      t.timestamps
    end

    # Each identity belongs to a user, and each user must not belong
    # to more than a single identity.
    add_column :identities, :user_id, :integer
    add_index  :identities, [ :user_id, :id, :type ], :unique => true
  end
end
