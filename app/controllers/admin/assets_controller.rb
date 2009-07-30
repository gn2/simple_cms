class Admin::AssetsController < Admin::BaseController

  make_resourceful do
    
    belongs_to :page
    
    actions :all

    response_for :show_fails do
      raise $!
    end
  end

end
