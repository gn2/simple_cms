class AddPages < ActiveRecord::Migration
  def self.up
    Layout.create({:name => 'default'})
    
    Page.create({:title => "projects", :layout_id => 1})
    Page.create({:title => "project1", :parent_id => 1, :layout_id => 1})
    Page.create({:title => "project2", :parent_id => 1, :layout_id => 1})
    Page.create({:title => "project3", :parent_id => 1, :layout_id => 1})
    Page.create({:title => "project4", :parent_id => 1, :layout_id => 1})
    Page.create({:title => "subproject21", :parent_id => 3, :layout_id => 1})
    Page.create({:title => "subproject22", :parent_id => 3, :layout_id => 1})
    Page.create({:title => "subproject23", :parent_id => 3, :layout_id => 1})
  end

  def self.down
    Page.destroy_all
  end
end
