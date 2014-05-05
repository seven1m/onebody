require_relative '../test_helper'

class PageTest < ActiveSupport::TestCase

  should "update path when saved" do
    @foo = Page.create!(slug: 'foo', title: 'Foo', body: 'foo rocks')
    assert_equal 'foo', @foo.path
    @bar = Page.create!(slug: 'bar', title: 'Boo', body: 'bar is the bomb', parent: @foo)
    assert_equal 'foo/bar', @bar.path
  end

  should "always have a lowercase slug with no spaces or symbols other than underscore" do
    assert Page.create(slug: 'hello',     title: 'Foo', body: 'foo rocks').valid?
    assert Page.create(slug: 'foo_foo',   title: 'Foo', body: 'foo rocks').valid?
    assert Page.create(slug: 'Foo',       title: 'Foo', body: 'foo rocks').errors[:slug]
    assert Page.create(slug: 'Foo_Foo',   title: 'Foo', body: 'foo rocks').errors[:slug]
    assert Page.create(slug: 'Foo*^!Foo', title: 'Foo', body: 'foo rocks').errors[:slug]
  end

  should "find a page by its path" do
    @parent = FactoryGirl.create(:page, slug: 'foo')
    assert_equal @parent, Page.find('foo')
    @child = FactoryGirl.create(:page, slug: 'baz', parent: @parent)
    assert_equal @child, Page.find('foo/baz')
  end

  should "find home page by its path" do
    @page = FactoryGirl.create(:page, slug: 'home')
    assert_equal @page, Page.find('')
  end

  should "find a page by its id" do
    @page = FactoryGirl.create(:page)
    assert_equal @page, Page.find(@page.id)
    assert_equal @page, Page.find(@page.id.to_s)
  end

  should "raise RecordNotFound if page does not exist" do
    assert_raise(ActiveRecord::RecordNotFound) do
      Page.find('does/not/exist')
    end
  end

  should "not allow a slug of 'admin' or 'edit' or 'new'" do
    @page1 = Page.create(slug: 'admin', title: 'Admin', body: '')
    assert @page1.errors[:slug]
    @page2 = Page.create(slug: 'edit', title: 'Edit', body: '')
    assert @page2.errors[:slug]
    @page3 = Page.create(slug: 'new', title: 'New', body: '')
    assert @page3.errors[:slug]
  end

end
