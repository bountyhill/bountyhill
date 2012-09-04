class AddIdentityOptions < ActiveRecord::Migration
  def change
    add_column :identities, :options, :text
  end
end
