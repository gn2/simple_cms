class CreatePageParts < ActiveRecord::Migration
  def self.up
    create_table :page_parts do |t|
      t.text    :content
      t.integer :layout_part_id
      t.integer :page_id
      t.timestamps
    end
  end

  def self.down
    drop_table :page_parts
  end
end
