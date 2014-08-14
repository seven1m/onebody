require 'active_support/concern'

module Concerns
  module FileImage
    extend ActiveSupport::Concern

    def image
      return @img unless @img.nil?
      if File.exist?(file.path) and img = mini_magick_image
        @img = img
      else
        @img = false
      end
    end

    def image?
      image and %w(JPEG PNG GIF).include?(image[:format])
    end

    def width
      image[:width] if image?
    end

    def height
      image[:height] if image?
    end

    private

    def mini_magick_image
      begin
        img = MiniMagick::Image.new(file.path)
        img if img.valid?
      rescue
        # html files cause MiniMagick to freak out without an Exception class :-(
        nil
      end
    end
  end
end
