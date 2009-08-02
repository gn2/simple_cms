class Asset < ActiveRecord::Base
  # Making default asset sizes easily overwritable
  ASSET_SIZES = { 
    :tiny => "32x32#",
    :small => "64x64>",
    :medium => "128x128>",
    :large => "600x600>"
    }
  
  belongs_to :layout_part
  belongs_to :attachable, :polymorphic => true
  has_attached_file :data, :styles => ASSET_SIZES
  
  validates_attachment_presence :data, :on => :create
  
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
  
  # This method assumes you have images that corespond to the filetypes.
  # For example "image/png" becomes "image-png.png"
  def icon
    "#{data_content_type.gsub(/[\/\.]/,'-')}.png"
  end
end