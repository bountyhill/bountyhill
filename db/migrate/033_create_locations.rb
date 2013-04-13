class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string  "address"
      t.string  "radius"
      t.float   "latitude"
      t.float   "longitude"
      t.string  "stationary_type", :null => false
      t.integer "stationary_id",   :null => false
      t.timestamps
    end
  end
end
