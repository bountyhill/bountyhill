# encoding: UTF-8

class MoveTwitterHandleIntoNameColumn < ActiveRecord::Migration
  def up
    execute "UPDATE identities SET email=name, name='' WHERE type IN ('Identity::Twitter')"
  end

  def down
    execute "UPDATE identities SET name=email WHERE type IN ('Identity::Twitter')"
  end
end
