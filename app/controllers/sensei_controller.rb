class SenseiController < BaseController

  def home
    @page = Page.top_level.first
    render :template => "pages/#{@page.layout.name}_layout/layout"
  end


  def dispatch
    # The respond_to block respond alright if the Accept header is
    # set properly. But it doesn't work with the extension. Fixing that.
    # set_content_type_header
    # Removing extension if there is any
    params[:path].push(File.basename(params[:path].pop, ".*"))
    page = params[:path].join('-').downcase

    respond_to do |format|
      format.html do
        if static_page_exists?(page, :html)
          render :template => "static/#{page}"
        elsif dynamic_page_exists?(params[:path])
          render :template => "pages/#{@page.layout.name}_layout/layout"
        else
          render :template => 'static/404', :status => 404
        end
      end

      format.xml do
        if static_page_exists?(page, :xml)
          render :layout => false, :template => "static/#{page}"
        elsif dynamic_page_exists?(params[:path])
          render :layout => false, :xml => @page.to_xml(:except => [:created_at, :updated_at, :deleted_at, :page_id] ,:include => :page_parts)
        else
          render :layout => false, :template => 'static/404', :status => 404
        end
      end

    end # respond_to
  end

  def sitemap
  end

  private
  def static_page_exists?(page, extension = :html)
    # TODO: support all template languages
    static_page_exists = false
    ActionController::Base.view_paths.map{ |path| File.join(path, 'static') }.each do |static_path|
      static_page_exists = FileTest.exists?(File.join(static_path, "#{page}.#{extension.to_s}.haml")) unless static_page_exists
    end
    static_page_exists
  end

  def dynamic_page_exists?(path)
    @page = Page.find_by_permalink_and_parent_permalink(path)
    !@page.nil?
  end

  def set_content_type_header
    #FIXME: Desperate attempt to detect extension and set the right header
    # extension = File.extname(params[:path].last).delete('.').to_sym
    case File.extname(params[:path].last || "").delete('.').downcase
    when 'html': response["Content-Type"] = "text/html"
    when 'xml': response["Content-Type"] = "application/xml"
    else
      logger.info "Nope, nothing matched"
    end
  end
end