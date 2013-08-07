# encoding: UTF-8

class CreateDeferredActions < ActiveRecord::Migration
  def change
    create_table :deferred_actions do |t|
      t.string      :secret, :null => false, :unique => true  # secure key to validate action
      t.integer     :actor_id                                 # who performs?
      t.string      :action                                   # what to perform?
      t.text        :args                                     # action parameters
      
      t.datetime    :expires_at
      t.datetime    :performed_at                             # performed when?
      t.text        :error                                    # error message when failed.
      
      t.timestamps
    end
  end
end
