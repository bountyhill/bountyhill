# encoding: UTF-8

class AddSharedAtToShares < ActiveRecord::Migration
  def change
    add_column :shares, :application, :boolean
    add_column :shares, :shared_at, :datetime
  end
end
