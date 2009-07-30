class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.string   :title
      t.string   :state,          :default => "draft",     :null => false
      t.string   :permalink
      t.integer  :parent_id
      t.integer  :layout_id
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
    end
  end

  def self.down
    drop_table :pages
  end
end
