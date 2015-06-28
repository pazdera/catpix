require "catpix/version"

require "tco"
require "rmagick"
require "terminfo"

require "pp"

module Catpix
  def self.print_image(path, options=nil)
    options = default_options.merge! options

    img = Magick::Image::read(path).first
    resize! img, options[:limit_x], options[:limit_y]

    margins = get_margins img, options[:center_x], options[:center_y]
    margin_colour = options[:bg_fill] ? options[:bg] : nil

    print_vert_margin margins[:top], margin_colour

    # print left margin for the first row
    print_horiz_margin margins[:left], margin_colour

    # Print it
    img.each_pixel do |pixel, col, row|
      if pixel.opacity == 65535
        print_pixel options[:bg]
      else
        print_pixel get_normal_rgb pixel
      end

      if col >= img.columns - 1
        print_horiz_margin margins[:right], margin_colour
        puts

        unless row == img.rows - 1
          print_horiz_margin margins[:left], margin_colour
        end
      end
    end

    print_vert_margin margins[:bottom], margin_colour
  end

  private
  def self.default_options
    {
      :limit_x => 1.0,
      :limit_y => 0,
      :center_x => false,
      :center_y => false,
      :bg => nil,
      :bg_fill => false
    }
  end

  def self.print_pixel(colour=nil)
    if colour
      print "  ".bg colour
    else
      print "  "
    end
  end

  def self.get_screen_size
    th, tw = TermInfo.screen_size
    [tw / 2, th]
  end

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

    pp margins
    margins
  end

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

    pp tw, th
    pp width, height
    pp limit_x, limit_y

    # Resize the image if it's bigger than the limited viewport
    if iw > width or ih > height
      img.change_geometry "#{width}x#{height}" do |cols, rows, img|
        img.resize! (cols).to_i, (rows).to_i
      end
    end
  end

  def self.print_vert_margin(size, colour)
    tw, th = get_screen_size
    size.times do
      tw.times { print_pixel colour }
      puts
    end
  end

  def self.print_horiz_margin(size, colour)
    size.times { print_pixel colour }
  end

  def self.get_normal_rgb(pixel)
    [pixel.red, pixel.green, pixel.blue].map { |v| 255*(v/65535.0) }
  end
end
