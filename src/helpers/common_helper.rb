# frozen_string_literal: true
#
# Generic helper contains utility functions that do not
# belong to a particular helper
module GenericHelper
  def sanitize_filename(filename)
    filename.strip!
    # NOTE: File.basename doesn't work right with Windows paths on Unix
    # get only the filename, not the whole path
    filename.gsub!(%r{/^.*(\\|\/)/}, '')

    # Strip out the non-ascii character
    filename.gsub!(%r{/[^0-9A-Za-z.\-]/}, '_')

    filename
  end

  def pretty_time(time_in_milli_secs)
    Time.at(time_in_milli_secs / 1000).utc.strftime('%H:%M:%S')
  end
end

def is_admin? user_id
  admin_id = $config[:discord][:admin_id]
  user_id == admin_id
end

# adds color text printing to puts String
# use like puts "Hello world".red
class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def light_blue
    colorize(36)
  end
end
