class RenameUsersTable < ActiveRecord::Migration
  def up
    rename_table :users, :identities
    add_column :identities, :type, :string
  end

  def down
    remove_columns :identities, :type
    rename_table :identities, :users
  end
end
