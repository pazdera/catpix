# Copyright (c) 2015 Radek Pazdera <me@radek.io>
# Distributed under the MIT License (see LICENSE.txt)

require "rmagick"
require "tco"
require "terminfo"

module Catpix
  private
  def self.default_options
    {
      limit_x: 1.0,
      limit_y: 0,
      center_x: false,
      center_y: false,
      bg: nil,
      bg_fill: false,
      resolution: 'auto'
    }
  end

  @@resolution = nil

  def self.high_res?
    @@resolution == 'high'
  end

  def self.print_pixel(colour)
    if colour
      print "  ".bg colour
    else
      print "  "
    end
  end

  def self.can_use_utf8?
    ENV.values_at("LC_ALL", "LC_CTYPE", "LANG").compact.first.include?("UTF-8")
  end

  # Returns normalised size of the terminal window
  #
  # Catpix can use either two blank spaces to approximate a pixel in the
  # temrinal or the 'upper half block' and 'bottom half block' characters.
  #
  # Depending on which of the above will be used, the screen size
  # must be normalised accordingly.
  def self.get_screen_size
    th, tw = TermInfo.screen_size
    if high_res? then [tw, th * 2] else [tw / 2, th] end
  end

  def self.load_image(path)
    Magick::Image::read(path).first
  end

  # Scale the image down based on the limits while keeping the aspect ratio
  def self.resize!(img, limit_x=0, limit_y=0)
    tw, th = get_screen_size
    iw = img.columns
    ih = img.rows

    width = if limit_x > 0
      (tw * limit_x).to_i
    else
      iw
    end

    height = if limit_y > 0
      (th * limit_y).to_i
    else
      ih
    end

    # Resize the image if it's bigger than the limited viewport
    if iw > width or ih > height
      img.change_geometry "#{width}x#{height}" do |cols, rows, img_handle|
        img_handle.resize! (cols).to_i, (rows).to_i
      end
    end
  end

  # Returns the normalised RGB of a ImageMagick's pixel
  def self.get_normal_rgb(pixel)
    [pixel.red, pixel.green, pixel.blue].map { |v| 255*(v/65535.0) }
  end

  # Determine the margins based on the centering options
  def self.get_margins(img, center_x, center_y)
    margins = {}
    tw, th = get_screen_size

    x_space = tw - img.columns
    if center_x
      margins[:left] = x_space / 2
      margins[:right] = x_space / 2 + x_space % 2
    else
      margins[:left] = 0
      margins[:right] = x_space
    end

    y_space = th - img.rows
    if center_y
      margins[:top] = y_space / 2
      margins[:bottom] = y_space / 2 + y_space % 2
    else
      margins[:top] = 0
      margins[:bottom] = 0
    end

    if high_res? and margins[:top] % 2 and margins[:bottom] % 2
      margins[:top] -= 1
      margins[:bottom] += 1
    end

    margins
  end

  def self.print_vert_margin(size, colour)
    tw, th = get_screen_size

    if high_res?
      (size / 2).times do
        tw.times { print get_two_pixels colour, colour }
        puts
      end
    else
      size.times do
        tw.times { print_pixel colour }
        puts
      end
    end
  end

  def self.print_horiz_margin(size, colour)
    if high_res?
      size.times { print get_two_pixels colour, colour }
    else
      size.times { print_pixel colour }
    end
  end
end
