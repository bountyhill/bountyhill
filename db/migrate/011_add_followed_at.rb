class AddFollowedAt < ActiveRecord::Migration
  def change
    add_column :identities, :followed_at, :datetime
  end
end
