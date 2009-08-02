xml.instruct!
xml.urlset :xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9' do
  @pages.each do |page|
    if page.visible?
      xml.url do
        xml.loc "http://" + SimpleConfig::Site.domain + page.url
        xml.lastmod page.updated_at.xmlschema
      end
    end
  end
end