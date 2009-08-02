class CreateAssets < ActiveRecord::Migration
  def self.up
    create_table :assets do |t|
      t.string   :name
      t.text     :caption
      t.integer  :position, :default => 0
      t.integer  :layout_part_id
      t.integer  :attachable_id
      t.string   :attachable_type
      t.string   :data_file_name
      t.string   :data_content_type
      t.integer  :data_file_size
      t.datetime :data_updated_at
      t.timestamps
    end

    add_index :assets, ["attachable_id"], :name => "index_attachings_on_attachable_id"
  end
  
  def self.down
    drop_table :assets
  end
end