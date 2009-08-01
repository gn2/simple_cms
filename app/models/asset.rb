class Asset < ActiveRecord::Base
  ASSET_SIZES = { :tiny => "64x64#",
               :small => "176x112#",
               :medium => "630x630>",
               :large => "1024x1024>" }
  
  belongs_to :asset, :counter_cache => true
  belongs_to :attachable, :polymorphic => true
  has_attached_file :data, :styles => ASSET_SIZES
  
  def url(*args)
    data.url(*args)
  end

  def name
    data_file_name
  end

  def content_type
    data_content_type
  end

  def browser_safe?
    %w(jpg gif png).include?(url.split('.').last.sub(/\?.+/, "").downcase)
  end
  alias_method :web_safe?, :browser_safe?

  # This method will replace one of the existing thumbnails with an file provided.
  def replace_style(style, file)
    style = style.downcase.to_sym
    if data.styles.keys.include?(style)
      if File.exist?(RAILS_ROOT + '/public' + a.data(style))
      end
    end
  end

  # This method assumes you have images that correspond to the filetypes.
  # For example "image/png" becomes "image-png.png"
  def icon
    "#{data_content_type.gsub(/[\/\.]/,'-')}.png"
  end
end