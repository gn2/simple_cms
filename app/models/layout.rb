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
  end
  
  # Nested attributes
  accepts_nested_attributes_for :layout_parts, :allow_destroy => true
  
end
