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

  def browser_safe?
    %w(jpg gif png).include?(url.split('.').last.sub(/\?.+/, "").downcase)
  end
  alias_method :web_safe?, :browser_safe?

  # This method assumes you have images that correspond to the filetypes.
  # For example "image/png" becomes "image-png.png"
  def icon
    "#{data_content_type.gsub(/[\/\.]/,'-')}.png"
  end

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
