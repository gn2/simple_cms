class Asset < ActiveRecord::Base
  # Making default asset sizes easily overwritable
  ASSET_SIZES = {
    :tiny => "32x32#",
    :small => "64x64>",
    :medium => "400x300>",
    :portrait => "150x250#",
    :large => "720x515>"
    }

  belongs_to :layout_part
  belongs_to :attachable, :polymorphic => true
  has_attached_file :data, :styles => ASSET_SIZES

  validates_attachment_presence :data, :on => :create

  # Instance method

  def url(*args)
    data.url(*args)
  end

  def filename
    data_file_name
  end

  def content_type
    data_content_type
  end

  def safe_name
    if name && !name.empty?
      name
    else
      File.basename(data_file_name, '.*').split('.').first.to_s.capitalize
    end
  end

  def browser_safe?
    %w(jpg gif png).include?(url.split('.').last.sub(/\?.+/, "").downcase)
  end
  alias_method :web_safe?, :browser_safe?

  # Class method

  # Set passed-in order for passed-in ids.
  def self.order(ids)
    if ids
      update_all(
        ['position = FIND_IN_SET(id, ?)', ids.join(',')],
        { :id => ids }
      )
    end
  end

end
