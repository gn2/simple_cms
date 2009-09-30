require 'net/http'
require 'uri'

class PageObserver < ActiveRecord::Observer
  include ActionController::UrlWriter
  observe Page

  def after_create(page)
    if SimpleConfig::Google.ping_sitemap
      RAILS_DEFAULT_LOGGER.info "[PING GOOGLE] A page has just been created... pinging google to check new sitemap."
      default_url_options[:host] = SimpleConfig::Site.domain
      Net::HTTP.get('www.google.com', '/ping?sitemap=' + URI.escape(sitemap_url))
    end
  end

end
