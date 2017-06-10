require 'active_support/concern'

module Concerns
  module FileImage
    extend ActiveSupport::Concern

    def image
      return @img unless @img.nil?
      @img = if file.path && File.exist?(file.path) && (img = mini_magick_image)
               img
             else
               false
             end
    end

    def image?
      !!image
    end

    def width
      image[:width] if image?
    end

    def height
      image[:height] if image?
    end

    private

    def mini_magick_image
      img = MiniMagick::Image.new(file.path)
      img if img.valid? && %w(JPEG PNG GIF).include?(img[:format])
    rescue
      # html files cause MiniMagick to freak out without an Exception class :-(
      nil
    end
  end
end
