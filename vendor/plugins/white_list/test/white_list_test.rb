require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))

class WhiteListTest < Test::Unit::TestCase
  include WhiteListHelper
  public :contains_bad_protocols?

  WhiteListHelper.tags.each do |tag_name|
    define_method "test_should_allow_#{tag_name}_tag" do
      assert_white_listed "start <#{tag_name} title=\"1\" name=\"foo\">foo <bad>bar</bad> baz</#{tag_name}> end", %(start <#{tag_name} title="1">foo &lt;bad>bar&lt;/bad> baz</#{tag_name}> end)
    end
  end

  def test_should_allow_anchors
    assert_white_listed %(<a href="foo" onclick="bar"><script>baz</script></a>), %(<a href="foo"></a>)
  end

  %w(src width height alt).each do |img_attr|
    define_method "test_should_allow_image_#{img_attr}_attribute" do
      assert_white_listed %(<img #{img_attr}="foo" onclick="bar" />), %(<img #{img_attr}="foo" />)
    end
  end

  def test_should_handle_non_html
    assert_white_listed 'abc'
  end

  def test_should_handle_blank_text
    assert_white_listed nil
    assert_white_listed ''
  end

  def test_should_allow_custom_tags
    text = "<u>foo</u>"
    assert_equal(text, white_list(text, :tags => %w(u)))
  end

  def test_should_allow_custom_tags_with_attributes
    text = %(<fieldset foo="bar">foo</fieldset>)
    assert_equal(text, white_list(text, :attributes => ['foo']))
  end

  [%w(img src), %w(a href)].each do |(tag, attr)|
    define_method "test_should_strip_#{attr}_attribute_in_#{tag}_with_bad_protocols" do
      assert_white_listed %(<#{tag} #{attr}="javascript:bang" title="1">boo</#{tag}>), %(<#{tag} title="1">boo</#{tag}>)
    end
  end

  def test_should_flag_bad_protocols
    %w(about chrome data disk hcp help javascript livescript lynxcgi lynxexec ms-help ms-its mhtml mocha opera res resource shell vbscript view-source vnd.ms.radio wysiwyg).each do |proto|
      assert contains_bad_protocols?("#{proto}://bad")
    end
  end

  def test_should_accept_good_protocols
    WhiteListHelper.protocols.each do |proto|
      assert !contains_bad_protocols?("#{proto}://good")
    end
  end

  def test_should_reject_hex_codes_in_protocol
    assert contains_bad_protocols?("%6A%61%76%61%73%63%72%69%70%74%3A%61%6C%65%72%74%28%22%58%53%53%22%29")
    assert_white_listed %(<a href="&#37;6A&#37;61&#37;76&#37;61&#37;73&#37;63&#37;72&#37;69&#37;70&#37;74&#37;3A&#37;61&#37;6C&#37;65&#37;72&#37;74&#37;28&#37;22&#37;58&#37;53&#37;53&#37;22&#37;29">1</a>), "<a>1</a>"
  end

  def test_should_block_script_tag
    assert_white_listed %(<SCRIPT\nSRC=http://ha.ckers.org/xss.js></SCRIPT>), ""
  end

  [%(<IMG SRC="javascript:alert('XSS');">), 
   %(<IMG SRC=javascript:alert('XSS')>), 
   %(<IMG SRC=JaVaScRiPt:alert('XSS')>), 
   %(<IMG """><SCRIPT>alert("XSS")</SCRIPT>">),
   %(<IMG SRC=javascript:alert(&quot;XSS&quot;)>),
   %(<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>),
   %(<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>),
   %(<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>),
   %(<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>),
   %(<IMG SRC="jav\tascript:alert('XSS');">),
   %(<IMG SRC="jav&#x09;ascript:alert('XSS');">),
   %(<IMG SRC="jav&#x0A;ascript:alert('XSS');">),
   %(<IMG SRC="jav&#x0D;ascript:alert('XSS');">),
   %(<IMG SRC=" &#14;  javascript:alert('XSS');">),
   %(<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>)].each_with_index do |img_hack, i|
    define_method "test_should_not_fall_for_xss_image_hack_#{i}" do
      assert_white_listed img_hack, "<img>"
    end
  end
  
  def test_should_sanitize_tag_broken_up_by_null
    assert_white_listed %(<SCR\0IPT>alert(\"XSS\")</SCR\0IPT>), "&lt;scr>alert(\"XSS\")&lt;/scr>"
  end
  
  def test_should_sanitize_invalid_script_tag
    assert_white_listed %(<SCRIPT/XSS SRC="http://ha.ckers.org/xss.js"></SCRIPT>), ""
  end
  
  def test_should_sanitize_script_tag_with_multiple_open_brackets
    assert_white_listed %(<<SCRIPT>alert("XSS");//<</SCRIPT>), "&lt;"
    assert_white_listed %(<iframe src=http://ha.ckers.org/scriptlet.html\n<), %(&lt;iframe src="http:" />&lt;)
  end
  
  def test_should_sanitize_unclosed_script
    assert_white_listed %(<SCRIPT SRC=http://ha.ckers.org/xss.js?<B>), "<b>"
  end
  
  def test_should_sanitize_half_open_scripts
    assert_white_listed %(<IMG SRC="javascript:alert('XSS')"), "<img>"
  end
  
  def test_should_not_fall_for_ridiculous_hack
    img_hack = %(<IMG\nSRC\n=\n"\nj\na\nv\na\ns\nc\nr\ni\np\nt\n:\na\nl\ne\nr\nt\n(\n'\nX\nS\nS\n'\n)\n"\n>)
    assert_white_listed img_hack, "<img>"
  end

  def test_should_allow_custom_block
    html = %(<SCRIPT type="javascript">foo</SCRIPT><img>blah</img><blink>blah</blink>)
    safe = white_list html do |node, bad|
      bad == 'script' ? nil : node
    end
    assert_equal "<img>blah</img><blink>blah</blink>", safe
  end

  def test_should_sanitize_attributes
    assert_white_listed %(<SPAN title="'><script>alert()</script>">blah</SPAN>), %(<span title="'&gt;&lt;script&gt;alert()&lt;/script&gt;">blah</span>)
  end

  protected
    def assert_white_listed(text, expected = nil)
      assert_equal((expected || text), white_list(text))
    end
end
