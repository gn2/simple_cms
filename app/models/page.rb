class Page < ActiveRecord::Base
  include AASM
  is_paranoid
  state_machine_history
  # TODO:change to position
  acts_as_tree :order => "title"
  has_permalink :title, :update => true
  acts_as_polymorphic_paperclip
  
  attr_protected :permalink
  attr_readonly :layout_id
  
  # Validations
  validates_presence_of :title
  validates_presence_of :layout
  validates_uniqueness_of :title, :scope => :parent_id, :message => "should be unique within a category", :case_sensitive => false 
  validates_each :parent_id do |record, attr, value|
    record.errors.add(attr, 'must be a different page') if value == record.id
  end 
  
  # Relationships
  belongs_to :layout
  has_many :page_parts, :dependent => :destroy do
    def with_layout_part(identifier)
      case identifier
      when String: find(:first, :joins => [:layout_part], :conditions => {:layout_parts => {:name => identifier}})
      when Integer: find(:first, :joins => [:layout_part], :conditions => {:layout_parts => {:id => identifier}})
      end
    end
    
    def content(layout_part_name)
      page_part = find(:first, :joins => [:layout_part], :conditions => {:layout_parts => {:name => layout_part_name}})
      page_part.nil? ? nil : page_part.content
    end
  end
  
  # Nested attributes
  accepts_nested_attributes_for :page_parts, :allow_destroy => true
  
  # Named scope
  named_scope :published, :conditions => { :status => "published" }
  named_scope :draft, :conditions => { :status => "draft" }
  named_scope :top_level, :conditions => { :parent_id => nil }
    
  # AASM configuration
  aasm_column :state
  aasm_initial_state :draft
  aasm_state :draft
  aasm_state :published
  
  aasm_event :publish do
    transitions :to => :published, :from => [:draft, :published]
  end
  aasm_event :hide do
    transitions :to => :draft, :from => [:published, :draft]
  end

  # Instance methods
  
  # Build the url of a page.
  # URL: /:parent_parent_permalink/:parent_permalink/:permalink
  def url
    page = self
    url = "/#{self.permalink}"
    while !page.parent.nil?
      page = page.parent
      url = "/#{page.permalink}#{url}"
    end
    
    return url
  end
  
  # Nicer names for states
  def nice_state
    case state
    when 'draft': "a <strong>draft</strong>"
    else
      "<strong>#{state}</strong>"
    end
  end
  
  # Wether the page should be displayed or not
  def visible?
    self.ancestors.inject(self.published?) { |result,page| result = page.published? if result }
  end
  
  # Counting associated assets
  def associated_assets_count
    # self.page_parts.inject(0) { |sum,page_part| page_part.layout_part.content_type=='asset' ? sum + 1 : sum }
    self.assets.size
  end
  
  def maximum_assets_count
    self.layout.layout_parts.inject(0) { |sum,layout_part| layout_part.content_type=='asset' ? sum + 1 : sum }
  end
  
  def missing_assets_count
    maximum_assets_count - associated_assets_count
  end
  
  # Class methods
  
  # Find a page using a concatenation of a page's permalink
  # and its parent page's permalink.
  # URL: /:blah_blah/:parent_permalink/:permalink
  def self.find_by_permalink_and_parent_permalink(path, include_drafts=false)
    page = nil
    page_permalink = path.pop
    parent_page_permalink = path.pop

    # If we have a page without parent
    if parent_page_permalink.nil?
      page = find(:first, :conditions => {:permalink => page_permalink, :parent_id => nil})
    # If there is a parent
    else
      pages_with_permalink = find(:all, :conditions => {:permalink => page_permalink})
      while page.nil? && !pages_with_permalink.empty?
        p = pages_with_permalink.shift
        # If we find a parent
        page = p if p.parent && p.parent.permalink == parent_page_permalink
      end
    end
    
    # At this we have found the page. Now we check if the page should be displayed
    return (page && (include_drafts || page.visible?)) ? page : nil
  end
end
