require "catpix/version"

require "tco"
require "rmagick"
require "terminfo"

require "pp"

module Catpix
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

  def self.print_image(path, options=nil)
    options = default_options.merge! options

    img = Magick::Image::read(path).first
    resize! img, options[:limit_x], options[:limit_y]

    margins = get_margins img, options[:center_x], options[:center_y]
    tw, th = get_screen_size

    margins[:top].times do
      tw.times do
        print_pixel options[:bg_fill] ? options[:bg] : nil
      end
      puts
    end

    # print left margin for the first row
    margins[:left].times do
      print_pixel options[:bg_fill] ? options[:bg] : nil
    end

    # Print it
    img.each_pixel do |pixel, col, row|
      if pixel.opacity == 65535
        print_pixel options[:bg]
      else
        c = [pixel.red, pixel.green, pixel.blue].map { |v| 255*(v/65535.0) }
        print_pixel c
      end

      if col >= img.columns - 1
        margins[:right].times do
          print_pixel options[:bg_fill] ? options[:bg] : nil
        end

        puts

        unless row == img.rows - 1
          margins[:left].times do
            print_pixel options[:bg_fill] ? options[:bg] : nil
          end
        end
      end
    end

    margins[:bottom].times do
      tw.times do
        print_pixel options[:bg_fill] ? options[:bg] : nil
      end
      puts
    end
  end
end
