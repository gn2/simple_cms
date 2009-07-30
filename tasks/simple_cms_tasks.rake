namespace :simple_cms do
  desc "Sync extra files from simple_users plugin"
  task :sync do
    system "rsync -ruv vendor/plugins/simple_cms/db/migrate db"
    system "rsync -ruv vendor/plugins/simple_cms/public ."
  end
  
  desc "Add layouts in the database using their manifest files"
  task :layouts => :environment do
    # Scanning app views pages directory
    ActionController::Base.view_paths.map{ |path| File.join(path, %w[ pages ** ]) }.each do |view_path|
      Dir[view_path].each do |layout|
        name = File.basename(layout).gsub(/_layout$/, '')
        puts "Found layout '#{name}' in #{File.dirname(layout)}"
      
        # Check for existing layout
        # Could be interesting to check if some pages are actually using that layout
        existing_layout = Layout.find_by_name(name)
        if existing_layout
          print "  This layout already exists. Do you want to overwrite it? (you could break existing pages using that layout!) (y/n)? "
          overwrite = STDIN.gets
          next unless overwrite.downcase.strip =~ /^(yes|y)$/
        end
      
        ActiveRecord::Base.transaction do
          existing_layout.destroy if existing_layout
        
          # Loading manifest
          raise "Manifest file not found" unless FileTest.exists?("#{layout}/manifest.yml")
          manifest = YAML::load_file("#{layout}/manifest.yml")
      
          raise "Manifest does not have a valid layout name" unless manifest['layout'] && manifest['layout']['name'] && !manifest['layout']['name'].blank?
          raise "Layout name in manifest does not match folder name" unless manifest['layout']['name'] == name
          raise "Layout does not have any layout parts" unless manifest['layout_parts'] && manifest['layout_parts'].size > 0
      
          # Adding layout in db
          puts "  Creating layout object for '#{name}'"
          layout_object = Layout.create({:name => name})
          raise "Layout could not be saved in the database" unless layout_object.valid?
      
          # Adding layout_parts in db
          puts "  Creating #{manifest['layout_parts'].size} layout_part object(s) for '#{name}'"
          manifest['layout_parts'].each_with_index do |layout_part, index|
            raise "Layout part ##{index+1} does not have a valid name" unless layout_part['name'] && !layout_part['name'].blank?
            raise "Layout part ##{index+1} does not have a valid content_type" unless layout_part['content_type'] && !layout_part['content_type'].blank?
            layout_part_object = LayoutPart.create({
              :name => layout_part['name'], 
              :content_type => layout_part['content_type'], 
              :position => index+1, 
              :layout_id => layout_object.id 
            })
            raise "Layout could not be saved in the database" unless layout_part_object.valid?
          end
        
        end # ActiveRecord::Base.transaction
      end # Dir
    end # Viewpath loop
      
  end # layouts task
end