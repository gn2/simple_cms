class Page < ActiveRecord::Base
  include AASM
  is_paranoid
  state_machine_history
  acts_as_tree :order => "position"
  has_permalink :title, :update => true

  attr_protected :permalink
  attr_readonly :layout_id

  # Validations
  validates_presence_of :title
  validates_presence_of :layout
  validates_uniqueness_of :title, :scope => [:parent_id, :deleted_at], :message => "should be unique within a category", :case_sensitive => false
  validates_each :parent_id do |record, attr, value|
    record.errors.add(attr, 'must be a different page') if value && value == record.id
  end

  # Relationships
  belongs_to :layout
  has_many :assets, :as => :attachable, :dependent => :destroy do
    def with_layout_part(identifier)
      case identifier
      when String: find(:all, :joins => [:layout_part], :conditions => {:layout_parts => {:name => identifier}}, :order => :position)
      when Integer: find(:all, :joins => [:layout_part], :conditions => {:layout_parts => {:id => identifier}}, :order => :position)
      end
    end

    def content(layout_part_name)
      assets = find(:all, :joins => [:layout_part], :conditions => {:layout_parts => {:name => layout_part_name.to_s}}, :order => :position)
      case assets.size
      when 0: nil
      when 1: assets.first
      else
        assets
      end
    end

    def associated_count
      count(:layout_part_id, :distinct => true)
    end
  end
  has_many :page_parts, :dependent => :destroy do
    def with_layout_part(identifier)
      case identifier
      when String: find(:first, :joins => [:layout_part], :conditions => {:layout_parts => {:name => identifier}})
      when Integer: find(:first, :joins => [:layout_part], :conditions => {:layout_parts => {:id => identifier}})
      end
    end

    def content(layout_part_name)
      page_part = find(:first, :joins => [:layout_part], :conditions => {:layout_parts => {:name => layout_part_name.to_s}})
      page_part.nil? ? nil : page_part.content
    end
  end

  # Delegate

  # Nested attributes
  accepts_nested_attributes_for :page_parts, :allow_destroy => true

  # Named scope
  named_scope :published, :conditions => { :state => "published" }
  named_scope :draft, :conditions => { :state => "draft" }
  named_scope :with_layout, lambda {|*args| {:include => :layout, :conditions => {:layouts => {:name => args.first.to_s}}} }
  named_scope :top_level, :conditions => { :parent_id => nil }, :order => :position
  named_scope :for_sitemap, :select => 'id, state, permalink, parent_id, updated_at', :order => 'updated_at DESC', :limit => 50000

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

  # Find top parent
  def top_parent
    page = self
    while !page.parent.nil?
      page = page.parent
    end
    return page
  end

  def parent_of?(child, page=self)
    if page == child || page.children.empty?
      return false
    elsif page.children.include?(child)
      return true
    else
      result = false
      page.children.each do |child_page|
        result = child_page.parent_of?(child, child_page) unless result
      end
      return result
    end
  end

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
  #TODO: Move that to a helper. It's really a view thing.
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

  def has_children?
    !self.children.empty?
  end

  # Counting assets
  def maximum_assets_count
    self.layout.assets_count + self.layout.assets_collection_count
  end
  def missing_assets_count
    maximum_assets_count - self.assets.associated_count
  end
  def assets_count
    self.assets.associated_count
  end

  # Simple access to page content
  def content(layout_part_name)
    case self.layout.layout_parts.content_type(layout_part_name)
    when 'asset','assets_collection'
      self.assets.content(layout_part_name)
    else
      # This returns nil if nothing is found
      self.page_parts.content(layout_part_name)
    end
  end

  def update_parent(new_parent_id)
    if new_parent_id
      new_parent_id = new_parent_id.to_i
      new_parent_id = nil if new_parent_id == 0
      update_attribute(:parent_id, new_parent_id)
    end
  end

  # Class methods

  # Find a page using a concatenation of a page's permalink
  # and its parent page's permalink.
  # URL: /:blah_blah/:parent_permalink/:permalink
  def self.find_by_permalink_and_parent_permalink(path, include_drafts=false)
    page = page_permalink = parent_page_permalink = nil
    page_permalink = path.pop if path
    parent_page_permalink = path.pop if path

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

  # Set passed-in order for passed-in ids.
  def self.order(ids)
    if ids
      update_all(
        ['position = FIND_IN_SET(id, ?)', ids.join(',')],
        { :id => ids }
      )
    end
  end

  def self.find_first_page_without_layout(pages, layout_array, method = :breadth_first)
    case method
    when :breadth_first
      pages.each do |page|
        if page.visible? && !layout_array.include?(page.layout.name.to_sym)
          return page
        end
      end
      # If nothing found, we try each child of each page
      page_found = nil
      pages.each do |page|
        break if page_found
        next unless page.has_children?
        page_found = Page.find_first_page_without_layout(page.children, layout_array, :breadth_first)
      end
      return page_found

    when :depth_first
      page_found = nil
      pages.each do |page|
        break if page_found
        if page.visible? && !layout_array.include?(page.layout.name.to_sym)
          return page
        end
        next unless page.has_children?
        page_found = Page.find_first_page_without_layout(page.children, layout_array, :depth_first)
      end
      return page_found

    end # case
  end # find_first_page_without_layout

  def self.random
    self.find(:first, :offset => rand(self.count()))
  end

  def self.random_with_layout(layout="", count=1)
    self.find(
      :all,
      :include => :layout,
      :conditions => {
        :state => 'published',
        :layouts => {:name => layout.to_s}
      },
      :order => "RAND()",
      :limit => count.to_s
    )
  end

  def self.random_with_layout_and_page_part(layout="", page_part="", count=1)
    self.find(
      :all,
      :joins => [{:page_parts => :layout_part}, :layout],
      :conditions => {
        :state => 'published',
        :page_parts => {
          :layout_parts => {:name => page_part.to_s}
        },
        :layouts => {:name => layout.to_s}
      },
      :order => "RAND()",
      :limit => count.to_s
    )
  end


  def self.random_with_layout_and_asset(layout="", page_part="", count=1)
    self.find(
      :all,
      :joins => [{:assets => :layout_part}, :layout],
      :conditions => {
        :state => 'published',
        :assets => {
          :layout_parts => {:name => page_part.to_s}
        },
        :layouts => {:name => layout.to_s}
      },
      :order => "RAND()",
      :limit => count.to_s
    )
  end


end
