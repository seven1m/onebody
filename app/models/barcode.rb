require 'gbarcode'

class Barcode
  include Gbarcode
  
  def initialize(text, minimum_length=3, pad_start_with='0')
    text = pad_start_with + text while text.length < minimum_length
    @text = text
    @bc = barcode_create(text)
    barcode_encode(@bc, BARCODE_128)
  end
  
  def to_jpg
    create_image
    File.open(@jpg_path, 'rb') do |jpg|
      @data = jpg.read
    end
    cleanup
    @data
  end
  
  private
  
    def create_image
      # This could probably be more efficient if the number of file reads and writes could be reduced.
      # MiniMagick::Image#to_blob seems to be broken on Windows,
      #   so we use the write/read/write/read method instead.
      @dir_name = create_temp_dir
      @eps_path = File.join(@dir_name, 'barcode.eps')
      File.open(@eps_path, 'wb') do |file|
        barcode_print(@bc, file, BARCODE_OUT_EPS) # barcode print cannot generate JPEG files
      end
      @img = MiniMagick::Image.from_file(@eps_path)
      @img.format('JPEG')
      @jpg_path = File.join(@dir_name, 'barcode.jpg')
      @img.write(@jpg_path)
    end
    
    def cleanup
      File.delete(@jpg_path)
      File.delete(@eps_path)
      Dir.rmdir(@dir_name)
    end
    
    def create_temp_dir
      # a cheap way to do tempfiles that Gbarcode will like
      # should be safe from race conditions (I think)
      failures = 0
      begin
        begin
          dir_name = File.join(RAILS_ROOT, 'tmp', Time.now.to_f.to_s)
          Dir.mkdir(dir_name)
        rescue
          failures += 1
          dir_name = nil
        end
      end while not dir_name and failures < 20
      if dir_name
        return dir_name
      else
        raise "Could not create temporary directory at #{File.join(RAILS_ROOT, 'tmp')}"
      end
    end
end
