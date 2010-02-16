class SenseiController < BaseController

  def home
    # Setting default home page
    mpage.page = Page.top_level.published.first
    mpage.render_from = :home

    # This allows you to fully customize the homepage
    before_render(mpage)
    mpage.freeze!

    render_page
  end # home

  def dispatch
    # Removing extension if there is any
    params[:path].push(File.basename(params[:path].pop, ".*"))
    mpage.page = params[:path].join('-').downcase
    mpage.render_from = :dispatch

    render_page
  end

  def sitemap
    @pages = Page.for_sitemap
    headers["Last-Modified"] = @pages[0].updated_at.httpdate if @pages[0]
    render :layout => false, :template => "pages/sitemap"
  end

  private
  def render_page
    # The respond_to block responds according to the Accept header.
    # But it doesn't work if you only change the extension in the
    # URL with the extension. (i.e. /about.xml will render an HTML
    # page, if Accept header is not set to application/xml)
    mpage.format = :html

    respond_to do |format|
      format.html do
        mpage.format = :html

        if !mpage.page.is_a?(Page) && static_page_exists?(mpage.page, :html)
          prepare_for_render(:static)
          render :template => "static/#{mpage.page}", :layout => mpage.layout

        elsif mpage.page.is_a?(Page) || (mpage.page = dynamic_page_exists?(params[:path]))
          prepare_for_render(:dynamic)
          render :template => "pages/#{mpage.page.layout.name}_layout/layout", :layout => mpage.layout

        else
          prepare_for_render(:not_found)
          render :template => 'static/404', :status => 404, :layout => mpage.layout
        end
      end

      format.xml do
        mpage.format = :xml

        if static_page_exists?(mpage.page, :xml)
          prepare_for_render(:static)
          render :layout => false, :template => "static/#{mpage.page}"

        elsif dynamic_page_exists?(params[:path])
          prepare_for_render(:dynamic)
          render :layout => false, :xml => mpage.page.to_xml(:except => [:created_at, :updated_at, :deleted_at, :page_id] ,:include => :page_parts)

        else
          prepare_for_render(:not_found)
          render :layout => false, :template => 'static/404', :status => 404
        end
      end

    end # respond_to

  end

  def static_page_exists?(page, extension = :html)
    # TODO: support all template languages
    static_page_exists = false
    ActionController::Base.view_paths.map{ |path| File.join(path, 'static') }.each do |static_path|
      static_page_exists = FileTest.exists?(File.join(static_path, "#{page}.#{extension.to_s}.haml")) unless static_page_exists
    end
    static_page_exists
  end

  def dynamic_page_exists?(path)
    page = Page.find_by_permalink_and_parent_permalink(path)
    !page.nil? && page
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

  def prepare_for_render(type)
    mpage.type = type
    before_render(mpage) unless mpage.frozen
    set_variables_for_render
  end

  def set_variables_for_render
    @page_tree = Page.top_level.published
    @page_title = mpage.page_title
    @page = mpage.page
  end

  protected
  # MetaPage object accessor
  def mpage
    @mpage ||= SimpleCms::MetaPage.new
  end

  # This method is meant to be overwritten in the main application to customize the dispatching
  def before_render(mpage)
    mpage
  end


end
