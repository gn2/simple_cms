class Admin::AssetsController < Admin::BaseController


  make_resourceful do
    belongs_to :page
    
    actions :all

    before :new, :create, :edit, :update, :show do
      @layout_part = (LayoutPart.exists?(params[:layout_part])) ? LayoutPart.find(params[:layout_part]) : current_object.layout_part || LayoutPart.first
    end

    response_for :show do |format|
      format.html { render :action => 'edit' }
    end

    response_for :show_fails do
      raise $!
    end
  end

end
