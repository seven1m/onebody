require 'gbarcode'

class Barcode
  include Gbarcode
  
  def initialize(text, minimum_length=3, pad_start_with='0')
    text = pad_start_with + text while text.length < minimum_length
    @text = text
    @bc = barcode_create(text)
    barcode_encode(@bc, BARCODE_128)
  end
  
  def to_gif
    create_image
    @img.format('GIF')
    @img.to_blob
  end
  
  private
  
    def create_image
      # a cheap way to do tempfiles that Gbarcode will like
      # should be safe from race conditions (I think)
      begin
        begin
          dir_name = File.join(RAILS_ROOT, 'tmp', Time.now.to_f.to_s)
          Dir.mkdir(dir_name)
        rescue
          dir_name = nil
        end
      end while not dir_name
      path = File.join(dir_name, 'barcode.eps')
      File.open(path, 'w') do |file|
        barcode_print(@bc, file, BARCODE_OUT_EPS)
      end
      @img = MiniMagick::Image.from_file(path)
      File.delete(path)
      Dir.rmdir(dir_name)
    end
end
