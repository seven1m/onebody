require File.dirname(__FILE__) + '/../test_helper'

class ComatosePageTest < Test::Unit::TestCase

  fixtures :comatose_pages

  should "create page" do
    assert_difference Comatose::Page, :count do
      page = create_page :title=>'New Page Name'
      assert !page.new_record?, "#{page.errors.full_messages.to_sentence}"
    end
  end

  should "create a new version of an updated page" do
    page = create_page
    assert_difference page, :version do
      page.update_attribute :body, "I'm the new content!"
      assert_equal "<p>I&#8217;m the new content!</p>", page.to_html
    end
  end

  should "render content through textile and liquid processors" do
    page = create_page :title=>'Title Here', :body=>'h1. {{page.title}}'
    assert_equal "<h1>Title Here</h1>", page.to_html
  end
  
  should "not allow creation of page when missing a title" do
    assert_no_difference Comatose::Page, :count do
      p = create_page(:title => nil)
      assert p.errors.on(:title)
    end
  end

  should "have good fixtures for this to work out" do
    assert_equal 'Home Page', root_page.title
    assert_equal 'home-page', root_page.slug
    assert_equal 'Comatose',  root_page.author
    assert_equal "",          root_page.full_path
    assert_equal 'faq',       faq_page.full_path
  end

  should "generate slugs correctly" do
    assert_equal 'hello-how-are-you',     new_page_slug( "Hello, How Are You?" )
    assert_equal 'i-have-too-much-space', new_page_slug( "I    have  too   much space" )
    assert_equal 'what-about-dashes',     new_page_slug( "What about - dashes?" )
    assert_equal 'a-bizarre-title',       new_page_slug( 'A !@!@#$%^<>&*()_+{} Bizarre TiTle!' )
    assert_equal '001-numbers-too',       new_page_slug( "001 Numbers too" )
  end
 
  should "generate page paths correctly" do
    products = root_page.children.create( :title=>'Products' )
    assert_equal 'products', products.full_path
 
    books = products.children.create( :title=>'Books' )
    assert_equal 'products/books', books.full_path
    
    novels = books.children.create( :title=>'Novels' )
    assert_equal 'products/books/novels', novels.full_path
 
    comics = books.children.create( :title=>'Comics' )
    assert_equal 'products/books/comics', comics.full_path
  end
  
  should "update page paths when pages are moved" do
    page = comatose_page :params
    assert_equal 'params', page.full_path
    
    q1pg = comatose_page :question_one
    page.parent_id = q1pg.id
    assert page.save, "Page.save"
    
    page.reload
    assert_equal 'faq/question-one/params', page.full_path

    q1pg.reload
    q1pg.slug = "q-1"
    assert q1pg.save, "Page.save"
    assert_equal "faq/q-1", q1pg.full_path

    page.reload
    assert_equal 'faq/q-1/params', page.full_path
  end

  should "render body text accurately" do
    assert_equal "<h1>Home Page</h1>\n\n\n\t<p>This is your <strong>home page</strong>.</p>", root_page.to_html
    assert_equal "<h1>Frequently Asked Questions</h1>\n\n\n\t<h2><a href=\"/faq/question-one\">Question One?</a></h2>\n\n\n<p>Content for <strong>question one</strong>.</p>\n\n\t<h2><a href=\"/faq/question-two\">Question Two?</a></h2>\n\n\n<p>Content for <strong>question two</strong>.</p>", faq_page.to_html
  end
 
  should "render data from parameterized calls too" do
    assert_equal "<p>I&#8217;m</p>", param_driven_page.to_html
    assert_equal "<p>I&#8217;m From the Params Hash</p>", param_driven_page.to_html(:extra=>'From the Params Hash')
  end
  
  should "render data from a Drop" do
    Comatose.define_drop "app" do
      def test
        "From Drop"
      end
    end
    p = create_page(:title=>'Test Drop', :body=>'{{ app.test  }}')
    assert_equal "<p>From Drop</p>", p.to_html
  end

  protected

    def new_page_slug(title)
      create_page( :title=>title ).slug
    end
    
    def root_page
      Comatose::Page.root
    end
    
    def faq_page
      comatose_page :faq
    end
    
    def param_driven_page
      comatose_page :params
    end
    
end
