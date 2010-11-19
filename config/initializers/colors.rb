COLOR_PALETTES = [
  ['Standard',   %w(5f9128 3286b5 333333)],
  ['Goldfish',   %w(5ab3c5 fa6900 003333)],
  ['Terra',      %w(cdb380 036564 031634)],
  ['Cake',       %w(e08e79 c5e0dc 774f38)],
  ['Ocean',      %w(00a0b0 cc333f 6a4a3c)],
  ['Hymn',       %w(2a044a a0c55f 0b2e59)],
 ]

module Sass::Script::Functions
  def edgevalue(color)
    if lightness(color).value >= 50
      Sass::Script::Color.new(:red => 0, :green => 0, :blue => 0)
    else
      Sass::Script::Color.new(:red => 255, :green => 255, :blue => 255)
    end
  end
end
