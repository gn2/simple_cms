class PagePart < ActiveRecord::Base
  belongs_to :page
  belongs_to :layout_part
  has_one :asset, :as => :attachable, :dependent => :destroy
  
  acts_as_markdown :content
end
