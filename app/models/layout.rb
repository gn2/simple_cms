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
    
    def assets_count
      inject(0) { |sum, layout_part| layout_part.content_type=='asset' ? sum + 1 : sum }
    end
  end
  
  # Delegate
  delegate :assets_count, :to => :layout_parts
  
  # Nested attributes
  accepts_nested_attributes_for :layout_parts, :allow_destroy => true
  
end
