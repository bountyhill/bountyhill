# encoding: UTF-8

class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|
      t.integer   'user_id',      :null => false
      t.string    'action',       :null => false
      t.integer   'object_id',    :null => false
      t.string    'object_type',  :null => false
      t.integer   'points',       :null => false
      t.datetime  'created_at',   :null => false
      t.datetime  'updated_at',   :null => false
    end
  end

  def self.down
    drop_table :activities
  end
end
