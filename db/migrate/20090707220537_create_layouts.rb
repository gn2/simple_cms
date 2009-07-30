class CreateLayouts < ActiveRecord::Migration
  def self.up
    create_table :layouts do |t|
      t.string  :name,      :limit => 100
      t.timestamps
    end
  end

  def self.down
    drop_table :layouts
  end
end
