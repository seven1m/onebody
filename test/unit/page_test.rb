require File.dirname(__FILE__) + '/../test_helper'

class PageTest < ActiveSupport::TestCase

  should "update path when saved" do
    @foo = Page.create!(:slug => 'foo', :title => 'Foo', :body => 'foo rocks')
    assert_equal 'foo', @foo.path
    @bar = Page.create!(:slug => 'bar', :title => 'Boo', :body => 'bar is the bomb', :parent => @foo)
    assert_equal 'foo/bar', @bar.path
  end

  should "always have a lowercase slug with no spaces or symbols other than underscore" do
    assert Page.create(:slug => 'hello',     :title => 'Foo', :body => 'foo rocks').valid?
    assert Page.create(:slug => 'foo_foo',   :title => 'Foo', :body => 'foo rocks').valid?
    assert Page.create(:slug => 'Foo',       :title => 'Foo', :body => 'foo rocks').errors.on(:slug)
    assert Page.create(:slug => 'Foo_Foo',   :title => 'Foo', :body => 'foo rocks').errors.on(:slug)
    assert Page.create(:slug => 'Foo*^!Foo', :title => 'Foo', :body => 'foo rocks').errors.on(:slug)
  end

  should "find a page by its path" do
    assert_equal pages(:foo), Page.find('foo')
    assert_equal pages(:baz), Page.find('foo/baz')
  end

  should "find home page by its path" do
    assert_equal pages(:home), Page.find('')
  end

  should "find a page by its id" do
    assert_equal pages(:foo), Page.find(pages(:foo).id)
    assert_equal pages(:foo), Page.find(pages(:foo).id.to_s)
  end

  should "raise RecordNotFound if page does not exist" do
    assert_raise(ActiveRecord::RecordNotFound) do
      Page.find('does/not/exist')
    end
  end

  should "not allow a slug of 'admin' or 'edit' or 'new'" do
    @page1 = Page.create(:slug => 'admin', :title => 'Admin', :body => '')
    assert @page1.errors.on(:slug)
    @page2 = Page.create(:slug => 'edit', :title => 'Edit', :body => '')
    assert @page2.errors.on(:slug)
    @page3 = Page.create(:slug => 'new', :title => 'New', :body => '')
    assert @page3.errors.on(:slug)
  end

end
