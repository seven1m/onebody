namespace :comatose do
  #
  # Data Migration Tasks
  #
  namespace :data do
    
    def page_to_hash(page)
      data = page.attributes.clone
      # Pull out the specific, or unnecessary fields
      %w(id parent_id updated_on author position version created_on full_path).each {|key| data.delete(key)}
      if !page.children.empty?
        data['children'] = []
        page.children.each do |child|
          data['children'] << page_to_hash(child)
        end
      end
      data
    end

    def hash_to_page_tree(hsh, page)
      child_ary = hsh.delete 'children'
      page.update_attributes(hsh)
      page.save
      child_ary.each do |child_hsh|
        if child_pg = page.children.find_by_slug( child_hsh['slug'] )
          hash_to_page_tree( child_hsh, child_pg )
        else
          hash_to_page_tree( child_hsh, page.children.create )      
        end
      end if child_ary
    end

    desc "Saves a page tree from page FROM or '' to file TO_FILE or db/comatose-pages.yml"
    task :export do 
      require "#{RAILS_ROOT}/config/environment"

      root = ENV['FROM'] || ''
      target = ENV['TO_FILE'] || 'db/comatose-pages.yml'
      # Nested hash of the page tree...
      from = Comatose::Page.find_by_path(root)
      if from
        data = page_to_hash( from ) 
        File.open(target, 'w') {|f| f.write data.to_yaml }
      else
        puts "Could not find the page at '#{root}', export aborted!"      
      end

      puts "Finished."
    end

    desc "Loads page tree data FROM_FILE or db/comatose-pages.yml in to TO or ComatosePage.root"
    task :import do 
      require "#{RAILS_ROOT}/config/environment"

      src = ENV['FROM_FILE'] || 'db/comatose-pages.yml'
      root = ENV['TO'] || ''
      target = (root == '') ? Comatose::Page.root : Comatose::Page.find_by_path(root)
      data = YAML::load( File.open(src) )
      #hash_to_page(data, target)
      if target
        if root == ''
          hash_to_page_tree(data, target)
        else
          if page = target.children.find_by_slug(data['slug'])
            hash_to_page_tree(data, page)
          else
            hash_to_page_tree(data, target.children.create)
          end
        end
      else
        puts "Could not find the page at '#{root}', import aborted!"
        # TODO: Ask to create the specified path if it doesn't exist?
      end
      puts "Finished."
    end

  end

end
