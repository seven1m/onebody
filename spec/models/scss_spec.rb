require_relative '../spec_helper'

describe 'SCSS' do

  it 'should calculate the coordinating edgevalue for a color' do
    result = render_css("#test { color: edgevalue(#fec) }")
    expect(result).to eq("#test{color:#000}")
    result = render_css("#test { color: edgevalue(#333) }")
    expect(result).to eq("#test{color:#fff}")
  end

  it 'should calculate the coordinating edgevalue for a color with an offset' do
    result = render_css("#test { color: edgevalue(#fec, 50) }")
    expect(result).to eq("#test{color:#323232}")
    result = render_css("#test { color: edgevalue(#333, 50) }")
    expect(result).to eq("#test{color:#cdcdcd}")
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
