require 'rails_helper'

describe 'Routes', type: :routing do
  it 'should route to news' do
    assert_routing '/news', controller: 'news', action: 'index'
    assert_routing '/news/1', controller: 'news', action: 'show', id: '1'
    expect(news_item_path(1)).to eq('/news/1')
    expect(news_path).to eq('/news')
    expect(news_items_path).to eq('/news')
  end

  it 'should route to pages' do
    assert_recognizes({ controller: 'pages', action: 'show_for_public', path: 'home' }, '/pages/home')
  end

  it 'should route to admin dashboard' do
    assert_routing '/admin', controller: 'administration/dashboards', action: 'show'
  end

  it 'should route in the admin namespace' do
    assert_routing '/admin/admins', controller: 'administration/admins', action: 'index'
  end
end
