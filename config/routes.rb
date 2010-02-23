ActionController::Routing::Routes.draw do |map|
  map.namespace(:admin) do |admin|
    # admin.resources :assets
    admin.resources :pages, :member => {:publish => :put, :hide => :put, :update_parent => :put}, :collection => {:sort => :put, :markitup_preview => :post} do |pages|
      pages.resources :assets, :collection => {:sort => :put}
    end
  end

  map.sitemap 'sitemap.xml', :controller => 'sensei', :action => 'sitemap'

  map.enter '/enter', :controller => "sensei", :action => 'enter'

  # To be added in /config/routes.rb
  # map.root :controller => "sensei", :action => 'home'
  # map.connect '*path.:format', :controller => 'sensei', :action => 'dispatch'
end
