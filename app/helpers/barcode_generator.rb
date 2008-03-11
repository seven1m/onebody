# $RAILS_ROOT/app/helpers/barcode_generator.rb
#
# note: this will not work without rmagick (Ruby ImageMagick interface) and gbarcode (GNU barcode) 
# gems installed. rmagick needs ImageMagick plus dependencies.

class BarcodeGenerator

  # Uses subprocesses because 
  # 1. ImageMagick/RMagick leaks memory,
  #    and doesn't work in a long-running process. The fork makes it safe.
  # 2. The output from the Gbarcode and ImageMagick is often longer than the pipe buffer,
  #    so we have to empty the buffer from another subprocess
  def BarcodeGenerator.get_barcode_image(barcode_string)
    return BarcodeGenerator.get_subprocess_output do
                   barcode_generator = BarcodeGenerator.new
                   $stdout.write(barcode_generator.get_barcode_image(barcode_string))
    end
  end

  def initialize
    # we do the imports here to protect long-running processes (like mongrel) from ImageMagick's memory leaks
    require 'RMagick'
    require 'gbarcode'
  end

  def get_barcode_image(string_to_encode)
    if string_to_encode.nil?
      string_to_encode = "No string specified"
    end
    string_to_encode = remove_rails_file_extension(string_to_encode)
    eps_barcode = get_barcode_eps(string_to_encode)
    gif_barcode = convert_eps_to_gif(eps_barcode)
    return gif_barcode
  end

  def remove_rails_file_extension(string_to_encode)
    if string_to_encode[-4..-1] == ".png"
      string_to_encode = string_to_encode[0..-5]
    end
    return string_to_encode
  end

  def get_barcode_eps(string_to_encode)
    barcode_object = Gbarcode.barcode_create(string_to_encode)
    Gbarcode.barcode_encode(barcode_object, Gbarcode::BARCODE_128)
    return BarcodeGenerator.get_subprocess_output do
        Gbarcode.barcode_print(barcode_object, $stdout, Gbarcode::BARCODE_OUT_EPS)    
    end
  end
  
  def convert_eps_to_gif(eps_image)
    base64_eps_image = Base64.encode64(eps_image)
    im = Magick::Image::read_inline(base64_eps_image).first
    im.format = "GIF"
    return BarcodeGenerator.get_subprocess_output do
       im.write($stdout) 
    end
  end

  # execute a block's code in a subprocess, returning any output
  def BarcodeGenerator.get_subprocess_output()
    data = ""
    IO.popen('-', 'r+') do |child_filehandle|
      if child_filehandle
        begin
          data = child_filehandle.read
        ensure
          child_filehandle.close_write
        end
      else
        yield
      end
    end
    return data
  end

end