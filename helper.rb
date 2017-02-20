module GenericHelper

  def sanitize_filename(filename)
    filename.strip!
    # NOTE: File.basename doesn't work right with Windows paths on Unix
    # get only the filename, not the whole path
    filename.gsub!(/^.*(\\|\/)/, '')

    # Strip out the non-ascii character
    filename.gsub!(/[^0-9A-Za-z.\-]/, '_')

    filename
  end

  def pretty_time time_in_milli_secs
    Time.at(time_in_milli_secs/1000).utc.strftime('%H:%M:%S')
  end

  def join_users_voice_channel_if_not_already discord_cbot, discord_event
    discord_user = discord_event.user
    cchannel = discord_event.channel
    vchannel = discord_user.voice_channel
    voice_bot = discord_event.voice

    # notify user if he's not in a voice channel
    if vchannel.nil?
      discord_cbot.send_message cchannel, "Pehlay ap kisi voice channel men to chalay jao sastay <@#{discord_user.id}>"
      return false
    end

    # do nothing if voice bot already connected to this server on users' voice channel
    if discord_cbot.voices[$config[:server_id]] && vchannel.id == voice_bot.channel.id
      puts "Already connected to voice channel #{voice_bot.channel.name}\nDoing noting"
      return voice_bot
    end

    # connect to users voice channel
    discord_cbot.voice_connect(vchannel)
    discord_cbot.send_message cchannel, "Voice channel: **#{vchannel.name}** men a gya."

    voice_bot
  end

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
