# http://blog.cynthiakiser.com/blog/2014/12/26/upgrading-from-rails-4-dot-1-8-to-4-dot-2-0/

module AssertSelectRoot
  def document_root_element
    html_document.root
  end
end

RSpec.configure do |config|
  config.include AssertSelectRoot, type: :request
end
