require "catpix/version"
require "catpix/private"

# Provides a function to print images in the terminal. A range of different
# formats is supported (check out what ImageMagick supports). Under the hood,
# this module uses two components:
#
# * [rmagick](https://rmagick.github.io/) to read and scale the images and
# * [tco](https://github.com/pazdera/tco) to map their pixels on the extended
#   colour palette in the terminal.
#
# Some other minor features like centering and handling background colours
# are supplied directly by this module.
module Catpix
  # Print an image to the terminal.
  #
  # All formats supported by ImageMagick are supported. The image's colours
  # will be mapped onto the extended 256 colour palette. Also by default, it
  # will be scaled down to fit the width of the terminal while keeping its
  # proportions. This can be changed using the `options` parameter.
  #
  # @param [Hash] options Adjust some parameters of the image when printed.
  # @option options [Float] :limit_x A factor of the terminal window's width.
  #                                  If present, the image will be scaled down
  #                                  to fit (proportions are kept). Using 0
  #                                  will disable the scaling. [default: 1.0]
  # @option options [Float] :limit_y A factor of the terminal window's height.
  #                                  If present, the image will be scaled down
  #                                  to fit (proportions are kept). Using 0
  #                                  will disable the scaling. [default: 0]
  # @option options [Boolean] :center_x Center the image horizontally in the
  #                                     terminal window. [default: false]
  # @option options [Boolean] :center_y Center the image vertically in the
  #                                     terminal window. [default: false]
  # @option options [String] :bg Background colour to use in case there are
  #                              any fully transparent pixels in the image.
  #                              This can be a RGB value '#c0ffee' or a tco
  #                              alias 'red' or 'blue'. [default: nil]
  # @option options [Boolean] :bg_fill Fill the margins around the image with
  #                                    background colour. [default: false]
  def self.print_image(path, options={})
    options = default_options.merge! options

    img = load_image path
    resize! img, options[:limit_x], options[:limit_y]

    margins = get_margins img, options[:center_x], options[:center_y]
    margin_colour = options[:bg_fill] ? options[:bg] : nil

    print_vert_margin margins[:top], margin_colour

    # print left margin for the first row
    print_horiz_margin margins[:left], margin_colour

    # print the image
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
end
