class CreateLayoutParts < ActiveRecord::Migration
  def self.up
    create_table :layout_parts do |t|
      t.string  :name,          :limit => 100
      t.integer :position
      t.string  :content_type,  :limit => 100
      t.integer :layout_id
      t.timestamps
    end
  end

  def self.down
    drop_table :layout_parts
  end
end
