require_relative '../test_helper'

class ScssTest < ActiveSupport::TestCase

  should 'calculate the coordinating edgevalue for a color' do
    result = render_css("#test { color: edgevalue(#fec) }")
    assert_equal "#test{color:#000}", result
    result = render_css("#test { color: edgevalue(#333) }")
    assert_equal "#test{color:#fff}", result
  end

  should 'calculate the coordinating edgevalue for a color with an offset' do
    result = render_css("#test { color: edgevalue(#fec, 50) }")
    assert_equal "#test{color:#323232}", result
    result = render_css("#test { color: edgevalue(#333, 50) }")
    assert_equal "#test{color:#cdcdcd}", result
  end

  def render_css(scss)
    Sass::Engine.new(
      scss,
      syntax: :scss,
      cache:  false,
      style:  :compressed
    ).render.strip
  end
end
