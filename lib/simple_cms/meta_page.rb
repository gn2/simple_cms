# Simple-cms
module SimpleCms
  class MetaPage
    attr_accessor :page, :type, :format, :layout, :render_from, :frozen

    def initialize
      @render_from = nil
      @format = :html
      @type = :static
      @layout = 'application'
      @frozen = false
    end

    def page_title
      if self.type == :dynamic && self.page.is_a?(Page)
        self.page.title
      elsif self.type == :static && self.page.is_a?(String)
        self.page.humanize
      else
        ""
      end
    end

    def freeze!
      @frozen = true
    end

    def frozen?
      @frozen
    end
  end
end
