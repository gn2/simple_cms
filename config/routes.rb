ActionController::Routing::Routes.draw do |map|
  map.namespace(:admin) do |admin|
    # admin.resources :assets    
    admin.resources :pages, :member => {:publish => :put, :hide => :put}, :collection => {:markitup_preview => :post} do |pages|
      pages.resources :assets
    end
  end
  
  # To be added in /config/routes.rb
  # map.root :controller => "sensei", :action => 'home'
  # map.connect '*path.:format', :controller => 'sensei', :action => 'dispatch'
end
