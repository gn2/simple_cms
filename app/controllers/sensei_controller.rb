class SenseiController < BaseController

  before_filter :load_data

  def home
    @page = Page.top_level.published.first
    @page = pre_process_page_object(@page, :home)
    set_page_title(@page)
    respond_to do |format|
      format.html do
        if @page
          render :template => "pages/#{@page.layout.name}_layout/layout"
        else
          render :template => 'static/404', :status => 404
        end
      end # format.html

      format.xml do
        if @page
          render :layout => false, :xml => @page.to_xml(:except => [:created_at, :updated_at, :deleted_at, :page_id] ,:include => :page_parts)
        else
          render :layout => false, :template => 'static/404', :status => 404
        end
      end # format.xml
    end # respond_to
  end # home

  def dispatch
    # The respond_to block responds according to the Accept header.
    # But it doesn't work if you only change the extension in the
    # URL with the extension. (i.e. /about.xml will render an HTML
    # page, if Accept header is not set to application/xml)

    # Removing extension if there is any
    params[:path].push(File.basename(params[:path].pop, ".*"))
    page = params[:path].join('-').downcase

    respond_to do |format|
      format.html do
        if static_page_exists?(page, :html)
          set_page_title(page)
          render :template => "static/#{page}"
        elsif dynamic_page_exists?(params[:path])
          @page = pre_process_page_object(@page, :dispatch)
          set_page_title(@page)
          render :template => "pages/#{@page.layout.name}_layout/layout"
        else
          set_page_title(@page)
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
    @pages = Page.for_sitemap
    headers["Last-Modified"] = @pages[0].updated_at.httpdate if @pages[0]
    render :layout => false, :template => "pages/sitemap"
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

  def load_data
    @page_tree = Page.top_level.published
  end

  def set_page_title(page)
    @page_title = page.title if page
  end

  def pre_process_page_object(page, from)
    page
  end

end
