# Copyright (c) 2015 Radek Pazdera <me@radek.io>
# Distributed under the MIT License (see LICENSE.txt)

require "rmagick"
require "tco"
require "terminfo"

module Catpix
  private
  MAX_OPACITY = 65535

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

  def self.can_use_utf8?
    ENV.values_at("LC_ALL", "LC_CTYPE", "LANG").compact.first.include?("UTF-8")
  end

  def self.prep_lr_pixel(colour)
    colour ? "  ".bg(colour) : "  "
  end

  def self.print_lr_pixel(colour)
    print prep_lr_pixel colour
  end

  def self.prep_hr_pixel(colour_top, colour_bottom)
    upper = "\u2580"
    lower = "\u2584"

    return " " if colour_bottom.nil? and colour_top.nil?
    return lower.fg colour_bottom if colour_top.nil?
    return upper.fg colour_top if colour_bottom.nil?

    c_top = Tco::match_colour colour_top
    c_bottom = Tco::match_colour colour_bottom
    if c_top == c_bottom
      return " ".bg "@#{c_top}"
    end

    upper.fg("@#{c_top}").bg("@#{c_bottom}")
  end

  def self.print_hr_pixel(colour_top, colour_bottom)
    print prep_hr_pixel colour_top, colour_bottom
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

  def self.prep_vert_margin(size, colour)
    tw, th = get_screen_size

    buffer = ""
    if high_res?
      (size / 2).times do
        sub_buffer = ""
        tw.times { sub_buffer += prep_hr_pixel nil, nil }
        buffer += sub_buffer.bg(colour) + "\n"
      end
    else
      size.times do
        sub_buffer = ""
        tw.times { sub_buffer += prep_lr_pixel nil }
        buffer += sub_buffer.bg(colour) + "\n"
      end
    end
    buffer
  end

  def self.prep_horiz_margin(size, colour)
    buffer = ""
    if high_res?
      size.times { buffer += prep_hr_pixel nil, nil }
    else
      size.times { buffer += prep_lr_pixel nil }
    end
    buffer.bg colour
  end

  # Print the image in low resolution
  def self.do_print_image_lr(img, margins, options)
    print prep_vert_margin margins[:top], margins[:colour]

    0.upto(img.rows - 1) do |row|
      buffer = prep_horiz_margin margins[:left], margins[:colour]
      0.upto(img.columns - 1) do |col|
        pixel = img.pixel_color col, row

        buffer += if pixel.opacity == MAX_OPACITY
          prep_lr_pixel options[:bg]
        else
          prep_lr_pixel get_normal_rgb pixel
        end
      end
      buffer += prep_horiz_margin margins[:right], margins[:colour]
      puts buffer
    end

    print prep_vert_margin margins[:bottom], margins[:colour]
  end

  # Print the image in high resolution (using unicode's upper half block)
  def self.do_print_image_hr(img, margins, options)
    print prep_vert_margin margins[:top], margins[:colour]

    0.step(img.rows - 1, 2) do |row|
      # line buffering makes it about 20% faster
      buffer = prep_horiz_margin margins[:left], margins[:colour]
      0.upto(img.columns - 1) do |col|
        top_pixel = img.pixel_color col, row
        colour_top = if top_pixel.opacity < MAX_OPACITY
          get_normal_rgb top_pixel
        else
          options[:bg]
        end

        bottom_pixel = img.pixel_color col, row + 1
        colour_bottom = if bottom_pixel.opacity < MAX_OPACITY
          get_normal_rgb bottom_pixel
        else
          options[:bg]
        end

        buffer += prep_hr_pixel colour_top, colour_bottom
      end
      buffer += prep_horiz_margin margins[:right], margins[:colour]
      puts buffer
    end

    print prep_vert_margin margins[:bottom], margins[:colour]
  end
end
