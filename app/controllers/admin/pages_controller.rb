class Admin::PagesController < Admin::BaseController

  before_filter :sidebar_data
  protect_from_forgery :except => [:markitup_preview] 

  def current_object
    @current_object ||= (Page.find(params[:id]) if Page.exists?(params[:id])) || Page.new
  end

  make_resourceful do
    actions :all
    
    before :new, :create, :edit, :update, :show do
      @layout = (Layout.exists?(params[:layout])) ? Layout.find(params[:layout]) : current_object.layout || Layout.first
    end

    response_for :show do |format|
      format.html { render :action => 'edit' }
    end
    
    
    response_for :show_fails do
      raise $!
    end
  end

  def publish
    current_object.publish!
    redirect_to admin_page_path(current_object)
  end
  
  def hide
    current_object.hide!
    redirect_to admin_page_path(current_object)
  end
  
  def markitup_preview
    render :text => RDiscount.new(params[:data]).to_html
  end
  
  def sort
    order = params[:page]
    Page.order(order)
    render :text => order.inspect
  end
  
  private
  def sidebar_data
    @top_level_pages = Page.top_level
    @layouts = Layout.all
  end
end
