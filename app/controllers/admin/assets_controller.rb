class Admin::AssetsController < Admin::BaseController

  make_resourceful do
    belongs_to :page

    actions :all

    before :new, :create, :edit, :update, :show do
      @layout_part = (LayoutPart.exists?(params[:layout_part])) ? LayoutPart.find(params[:layout_part]) : current_object.layout_part || LayoutPart.first
    end

    response_for :edit, :update, :show do |format|
      format.html { render :action => 'edit' }
      format.js   { render_to_facebox :action => 'edit' }
    end
    response_for :create, :update do |format|
      format.html { render :action => :index }
    end

    response_for :index, :new do |format|
      format.html
      format.js   { render_to_facebox }
    end

    after :create_fails, :update_fails do
      flash[:error] = ""
    end
  end

  def sort
    order = params[:asset]
    Asset.order(order)
    render :text => order.inspect
  end
end
