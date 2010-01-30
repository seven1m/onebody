require 'helper'
require 'lib/activeresource_test_case'

class DeserializerTest < Test::Unit::TestCase  
  def test_parameter_api
    collection = create(1, 5, 1337) {|pager| pager.replace([{:name => "will_paginate" }]) }
    projects_xml = collection.to_xml(:root => "projects")
    
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=5", {}, projects_xml
    end
    
    # :params parameter in options is required!
    assert_raise(ArgumentError){ Client::Project.paginate }
    assert_raise(ArgumentError){ Client::Project.paginate({}) }
    
    # :page parameter in :params is required!
    assert_raise(ArgumentError){ Client::Project.paginate(:params => {}) }
    
    # explicit :all should not break anything
    assert_equal Client::Project.paginate(:params => {:page => nil, :per_page => 5}).first.name, Client::Project.paginate(:all, :params => {:page => 1, :per_page => 5}).first.name
  end
  
  # ===================================
  # = Collection response from server =
  # ===================================
  
  def test_collection_without_entries
    collection = create(1, 5, 0)
    projects_xml = collection.to_xml
    
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=5", {}, projects_xml
    end
    
    projects = Client::Project.paginate(:params => {:page => 1, :per_page => 5}) 
    
    assert projects.kind_of?(WillPaginate::Collection)
    
    assert_equal 0, projects.size
    
    assert_equal 1, projects.current_page
    
    assert_equal 5, projects.per_page
    
    assert_equal 0, projects.total_entries    
    
    assert_equal nil, projects.first
  end
    
  def test_collection_with_one_entry
    collection = create(1, 5, 1337) {|pager| pager.replace([{:name => "will_paginate" }]) }
    projects_xml = collection.to_xml(:root => "projects")
    
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=5", {}, projects_xml
    end
    
    projects = Client::Project.paginate(:params => {:page => 1, :per_page => 5}) 
    
    assert projects.kind_of?(WillPaginate::Collection)
    
    assert_equal 1, projects.size
    
    assert_equal 1, projects.current_page
    
    assert_equal 5, projects.per_page
    
    assert_equal 1337, projects.total_entries    
    
    assert_equal "will_paginate", projects.first.name    
  end
  
  def test_collection_without_per_page_parameter
    default_per_page = Client::Project.per_page
    
    collection = create(1, default_per_page, 1337) {|pager| pager.replace([{:name => "will_paginate" }]) }
    projects_xml = collection.to_xml(:root => "projects")
    
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=#{default_per_page}", {}, projects_xml
    end
    
    projects = Client::Project.paginate(:params => {:page => 1})
    
    assert projects.kind_of?(WillPaginate::Collection)
    
    assert_equal 1, projects.size
    
    assert_equal 1, projects.current_page
    
    assert_equal default_per_page, projects.per_page
    
    assert_equal 1337, projects.total_entries    
    
    assert_equal "will_paginate", projects.first.name    
  end
  
  def test_collection_with_per_page_method
    Client::Project.stubs(:per_page).returns(8)

    default_per_page = 8
    
    collection = create(1, default_per_page, 1337) {|pager| pager.replace([{:name => "will_paginate" }]) }
    projects_xml = collection.to_xml(:root => "projects")
    
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=#{default_per_page}", {}, projects_xml
    end
    
    projects = Client::Project.paginate(:params => {:page => 1})
    
    assert projects.kind_of?(WillPaginate::Collection)
    
    assert_equal 1, projects.size
    
    assert_equal 1, projects.current_page
    
    assert_equal default_per_page, projects.per_page
    
    assert_equal 1337, projects.total_entries    
    
    assert_equal "will_paginate", projects.first.name    
  end
  
  def test_collection_with_multiple_entries
    collection = create(1, 5, 1337) {|pager| pager.replace([{:name => "will_paginate" }, {:name => "active_resource" }]) }
    projects_xml = collection.to_xml(:root => "projects")
    
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=5", {}, projects_xml
    end
    
    projects = Client::Project.paginate(:params => {:page => 1, :per_page => 5}) 
    
    assert projects.kind_of?(WillPaginate::Collection)
    
    assert_equal 2, projects.size    
    
    assert_equal 1, projects.current_page
    
    assert_equal 5, projects.per_page
    
    assert_equal 1337, projects.total_entries    
    
    assert_equal "active_resource", projects.last.name    
  end
  
  def test_collection_on_next_page_within_total
    collection = create(2, 1, 2) {|pager| pager.replace([{:name => "will_paginate" }]) }
    projects_xml = collection.to_xml(:root => "projects")
    
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=2&per_page=1", {}, projects_xml
    end
    
    projects = Client::Project.paginate(:params => {:page => 2, :per_page => 1}) 
    
    assert projects.kind_of?(WillPaginate::Collection)
    
    assert_equal 1, projects.size    
    
    assert_equal 2, projects.current_page
    
    assert_equal 1, projects.per_page
    
    assert_equal 2, projects.total_entries    
    
    assert_equal "will_paginate", projects.first.name    
  end
  
  def test_collection_on_next_page_outside_of_total
    collection = create(2, 2, 2) {|pager| pager.replace([]) }
    projects_xml = collection.to_xml(:root => "projects")
    
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=2&per_page=2", {}, projects_xml
    end
    
    projects = Client::Project.paginate(:params => {:page => 2, :per_page => 2}) 
    
    assert projects.kind_of?(WillPaginate::Collection)
    
    assert_equal 0, projects.size    
    
    assert_equal 2, projects.current_page
    
    assert_equal 2, projects.per_page
    
    assert_equal 2, projects.total_entries   
  end
  
  # ==============================
  # = Array response from server =
  # ==============================    
  
  def test_array_without_entries
    collection = []
    projects_xml = collection.to_xml
  
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=5", {}, projects_xml
    end
  
    projects = Client::Project.paginate(:params => {:page => 1, :per_page => 5}) 
  
    assert projects.kind_of?(WillPaginate::Collection)
  
    assert_equal 0, projects.size
  
    assert_equal 1, projects.current_page
  
    assert_equal 5, projects.per_page
  
    assert_equal 0, projects.total_entries    
  
    assert_equal nil, projects.first
  end
  
  def test_array_with_one_entry
    collection = [{:name => "will_paginate" }]
    projects_xml = collection.to_xml(:root => "projects")
  
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=5", {}, projects_xml
    end
  
    projects = Client::Project.paginate(:params => {:page => 1, :per_page => 5}) 
  
    assert projects.kind_of?(WillPaginate::Collection)
  
    assert_equal 1, projects.size
  
    assert_equal 1, projects.current_page
  
    assert_equal 5, projects.per_page
  
    assert_equal 1, projects.total_entries    
  
    assert_equal "will_paginate", projects.first.name    
  end
  
  def test_array_without_per_page_parameter
    default_per_page = Client::Project.per_page
  
    collection = [{:name => "will_paginate" }]
    projects_xml = collection.to_xml(:root => "projects")
  
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=#{default_per_page}", {}, projects_xml
    end
  
    projects = Client::Project.paginate(:params => {:page => 1})
  
    assert projects.kind_of?(WillPaginate::Collection)
  
    assert_equal collection.paginate.size, projects.size
  
    assert_equal 1, projects.current_page
  
    assert_equal default_per_page, projects.per_page
  
    assert_equal collection.paginate.total_entries, projects.total_entries    
  
    assert_equal "will_paginate", projects.first.name    
  end
  
  def test_array_with_per_page_method
    Client::Project.stubs(:per_page).returns(8)
    
    default_per_page = 8
    
    collection = [{:name => "will_paginate" }]
    projects_xml = collection.to_xml(:root => "projects")
    
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=#{default_per_page}", {}, projects_xml
    end
    
    projects = Client::Project.paginate(:params => {:page => 1})
  
    assert projects.kind_of?(WillPaginate::Collection)
  
    assert_equal collection.paginate.size, projects.size
  
    assert_equal 1, projects.current_page
  
    assert_equal default_per_page, projects.per_page
  
    assert_equal collection.paginate.total_entries, projects.total_entries    
  
    assert_equal "will_paginate", projects.first.name
  end
  
  def test_array_with_multiple_entries
    collection = [{:name => "will_paginate" }, {:name => "active_resource" }]
    projects_xml = collection.to_xml(:root => "projects")
  
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=1&per_page=5", {}, projects_xml
    end
  
    projects = Client::Project.paginate(:params => {:page => 1, :per_page => 5}) 
  
    assert projects.kind_of?(WillPaginate::Collection)
  
    assert_equal 2, projects.size    
  
    assert_equal 1, projects.current_page
  
    assert_equal 5, projects.per_page
  
    assert_equal 2, projects.total_entries    
  
    assert_equal "active_resource", projects.last.name    
  end
  
  def test_array_on_next_page_within_total
    collection = [{:name => "will_paginate" }, {:name => "active_resource" }]
    projects_xml = collection.to_xml(:root => "projects")
  
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=2&per_page=1", {}, projects_xml
    end
  
    projects = Client::Project.paginate(:params => {:page => 2, :per_page => 1}) 
  
    assert projects.kind_of?(WillPaginate::Collection)
  
    assert_equal 1, projects.size    
  
    assert_equal 2, projects.current_page
  
    assert_equal 1, projects.per_page
  
    assert_equal 2, projects.total_entries    
  
    assert_equal "active_resource", projects.first.name    
  end
  
  def test_array_on_next_page_outside_of_total
    collection = [{:name => "will_paginate" }, {:name => "active_resource" }]
    projects_xml = collection.to_xml(:root => "projects")
  
    ActiveResource::HttpMock.respond_to do |mock|      
      mock.get "/projects.xml?page=2&per_page=2", {}, projects_xml
    end
  
    projects = Client::Project.paginate(:params => {:page => 2, :per_page => 2}) 
  
    assert projects.kind_of?(WillPaginate::Collection)
  
    assert_equal 0, projects.size    
  
    assert_equal 2, projects.current_page
  
    assert_equal 2, projects.per_page
  
    assert_equal 2, projects.total_entries    
  end
private
  def create(page = 2, limit = 5, total = nil, &block)
    if block_given?
      WillPaginate::Collection.create(page, limit, total, &block)
    else
      WillPaginate::Collection.new(page, limit, total)
    end
  end  
end
