class PagePart < ActiveRecord::Base
  belongs_to :page
  belongs_to :layout_part  
  acts_as_markdown :content
end
