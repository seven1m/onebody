require_relative '../rails_helper'

describe Page do
  it 'should update path when saved' do
    @foo = Page.create!(slug: 'foo', title: 'Foo', body: 'foo rocks')
    expect(@foo.path).to eq('foo')
    @bar = Page.create!(slug: 'bar', title: 'Boo', body: 'bar is the bomb', parent: @foo)
    expect(@bar.path).to eq('foo/bar')
  end

  it 'should always have a lowercase slug with no spaces or symbols other than underscore' do
    expect(Page.create(slug: 'hello',     title: 'Foo', body: 'foo rocks')).to be_valid
    expect(Page.create(slug: 'foo_foo',   title: 'Foo', body: 'foo rocks')).to be_valid
    expect(Page.create(slug: 'Foo',       title: 'Foo', body: 'foo rocks').errors[:slug]).to be
    expect(Page.create(slug: 'Foo_Foo',   title: 'Foo', body: 'foo rocks').errors[:slug]).to be
    expect(Page.create(slug: 'Foo*^!Foo', title: 'Foo', body: 'foo rocks').errors[:slug]).to be
  end

  it 'should find a page by its path' do
    @parent = FactoryGirl.create(:page, slug: 'foo')
    expect(Page.find('foo')).to eq(@parent)
    @child = FactoryGirl.create(:page, slug: 'baz', parent: @parent)
    expect(Page.find('foo/baz')).to eq(@child)
  end

  it 'should find home page by its path' do
    @page = FactoryGirl.create(:page, slug: 'home')
    expect(Page.find('')).to eq(@page)
  end

  it 'should find a page by its id' do
    @page = FactoryGirl.create(:page)
    expect(Page.find(@page.id)).to eq(@page)
    expect(Page.find(@page.id.to_s)).to eq(@page)
  end

  it 'should raise RecordNotFound if page does not exist' do
    expect { Page.find('does/not/exist') }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "should not allow a slug of 'admin' or 'edit' or 'new'" do
    @page1 = Page.create(slug: 'admin', title: 'Admin', body: '')
    expect(@page1.errors[:slug]).to be
    @page2 = Page.create(slug: 'edit', title: 'Edit', body: '')
    expect(@page2.errors[:slug]).to be
    @page3 = Page.create(slug: 'new', title: 'New', body: '')
    expect(@page3.errors[:slug]).to be
  end
end
