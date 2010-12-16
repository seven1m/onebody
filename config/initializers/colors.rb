COLOR_PALETTES = [
  ['Standard',   %w(5f9128 3286b5 333333 e4e4e4)],
  ['Goldfish',   %w(5ab3c5 fa6900 003333 e4e4e4)],
  ['Terra',      %w(cdb380 036564 031634 e4e4e4)],
  ['Cake',       %w(e08e79 c5e0dc 774f38 e4e4e4)],
  ['Ocean',      %w(00a0b0 cc333f 6a4a3c e4e4e4)],
  ['Hymn',       %w(2a044a a0c55f 0b2e59 e4e4e4)],
 ]

module Sass::Script::Functions
  def edgevalue(color, offset=0)
    unless lightness(color).value >= 50
      offset = 255 - offset.to_i
    end
    Sass::Script::Color.new(:red => offset, :green => offset, :blue => offset)
  end
end
