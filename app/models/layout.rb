class Layout < ActiveRecord::Base
  # Validations
  validates_presence_of :name
  validates_uniqueness_of :name
  
  # Relationships
  has_many :pages
  has_many :layout_parts, :dependent => :destroy do
    def ordered
      find(:all, :order => :position)
    end
    
    def with_assets
      find(:all, :conditions =>  {:content_type => 'asset'})
    end
    
    def with_assets_collection
      find(:all, :conditions =>  {:content_type => 'assets_collection'})
    end
    
    def assets_count
      inject(0) { |sum, layout_part| layout_part.content_type=='asset' ? sum + 1 : sum }
    end
    
    def assets_collection_count
      inject(0) { |sum, layout_part| layout_part.content_type=='assets_collection' ? sum + 1 : sum }
    end
    
    def content_type(layout_part_name)
      layout_part = find(:first, :conditions =>  {:name => layout_part_name.to_s})
      layout_part ? layout_part.content_type : layout_part
    end
  end
  
  # Delegate
  delegate :assets_count, :to => :layout_parts
  delegate :assets_collection_count, :to => :layout_parts
    
  # Nested attributes
  accepts_nested_attributes_for :layout_parts, :allow_destroy => true
  
end
