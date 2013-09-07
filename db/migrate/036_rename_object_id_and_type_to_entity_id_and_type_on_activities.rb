class RenameObjectIdAndTypeToEntityIdAndTypeOnActivities < ActiveRecord::Migration
  def up
    rename_column :activities, :object_id,    :entity_id
    rename_column :activities, :object_type,  :entity_type
  end

  def down
    rename_column :activities, :entity_id,    :object_id
    rename_column :activities, :entity_type,  :object_type
  end
end
