# encoding: UTF-8

class RenameEndsAt < ActiveRecord::Migration
  def change
    rename_column "quests", :ends_at, :expires_at
  end
end
