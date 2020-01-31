require 'discordrb'
require 'soundcloud'

require 'pp'

require_relative 'config'
require_relative 'database'
require_relative 'helpers/common_helper'
require_relative 'helpers/soundcloud_helper'
require_relative 'helpers/youtube_helper'
require_relative 'helpers/giphy_helper'

class Obra
  include GenericHelper
  include SoundCloudHelper
  include YoutubeHelper
  include GiphyHelper

  # constants
  SOUND_EFFECTD_ROOT = 'data/sounds/effects/'
  DEFAULT_VOLUME = 15.25

  attr_reader :song_queue

  def initialize
    puts "In initializing OBRA"

    #Initialize Database
    @db = Database.get_db

    # Discordrb command bot
    discord_cbot_config = $config[:discord]
    @discord_cbot = Discordrb::Commands::CommandBot.new discord_cbot_config

    # this holds songs queued in form of {name: 'song name', local_path: 'path/to/song.mp3'...}
    @songs_queue = []

    # this holds songs searched, same format as above
    @searched_songs_queue = []

    # voice bot we use to play sounds/songs
    @voice_bot = nil

    # flag weather we are playing or not
    @stop_playing = nil

    # flag weather play same song over n over again or not
    @loop_playback = false
  end

  def run
    puts "Starting OBRA...\n"

    self.hook_commands
    @discord_cbot.run
  end

  def hook_commands
    t = Time.now

    @discord_cbot.command(:reset_levels) do |e, *args|
      return unless is_admin? e.user.id

      #@ranks_collection.delete_many {}
      ':boom: Resetted user levels :boom:'
    end

    @discord_cbot.command(:prune) do |e, *args|
      return unless is_admin? e.user.id

      n = args[0].to_i
      e.channel.prune n
      e.channel.send_temporary_message ":boom: Deleted last #{n} Messages :boom:", 3
    end

    # we track every message to give points to user
    #  and save it in DB
    #  user levels up at each power of 2 posts, 1, 2, 4, 8, 16 etc
    @discord_cbot.message(contains: '') do |e|
      user_id = e.author.id
      user = Database.get_or_create_user_rank_row user_id

      messages = user[1].to_i + 1

      # calculate level
      rank = Math.log2(messages).floor

      # if user leveled up, notify in channel
      if rank > user[2].to_i
        @discord_cbot.send_message e.channel.id, "<@#{user_id}> Just leveld up!\nHe's now Level #{rank} - #{$config[:lvl_titles][rank]}"
      end

      # save updated stats
      user = Database.update_user(user_id, messages, rank)
    end

    # reply user via PM if he mentions bot
    @discord_cbot.mention do |event|
      event.user.pm('Stop mentioning me... I am busy.')
    end

    # joins words passed by args and then use it as search term to search gif
    # returns a random gif from all the searched gifs
    @discord_cbot.command(:gif, description: 'Fetches a random gif from Giphy based on your query.', usage: '!gif cats') do |e,*args|
      gif_search args.join(' ')
    end

    # return leaderboards
    @discord_cbot.command(:levels, description: 'Ranks of Members based on their activity.', usage: '!levels') do |e|
      ret = "**User Levels:**\n\n"

      # get user ranks in descending order
      Database.top_ranked_users(11).each do |row|
        ret += "<@#{row[0]}> lvl#{row[1]} *#{$config[:lvl_titles][row[2]]}*\n"
      end

      ret
    end

    @discord_cbot.ready do |e|
      #p discord_cbot.servers
      puts "Running bot in #{$env} Environtment\n"
      puts "Inivte URL ".red + @discord_cbot.invite_url
      @discord_cbot.update_status('Playing', 'DivineLight', 'http://www.twitch.tv/divineslight')
    end

    @discord_cbot.command(:ping, description: 'To display Bot\'s ping.', usage: '!ping') do |e|
      ping_in_ms = ((Time.now - e.timestamp) * 1000).round
      "Pong! #{ping_in_ms}ms"
    end

    # echo back the PM sent to our bot
    @discord_cbot.private_message do |e|
      e.user.pm e.message.content
    end

    #NOTE: DiscordRb gem has bug cant play right now.
    # connects to your voice channel
    #@discord_cbot.command(:voice, description: 'Joins your voice channel.', usage: '!voice') do |e|
    #  user = e.user
    #  vchannel = e.user.voice_channel

    #  if vchannel.nil?
    #    "Please sit in a voice channel yourself <@#{user.id}>"
    #  else
    #    p "Voice Bot: #{@voice_bot.inspect}..."
    #    @voice_bot = @discord_cbot.voice_connect(vchannel)
    #    p "Voice Bot: #{@voice_bot.inspect}..."
    #    @voice_bot.volume = DEFAULT_VOLUME / 100.0
    #    "Connected to **##{vchannel.name}** - **Lets Go!**"
    #    p "Voice Bot: #{@voice_bot.inspect}..."
    #  end
    #end


    # disconnects from your voice channel
    #@discord_cbot.command(:leave, description: 'Leaves your voice channel!', usage: '!leave') do |e|
    #  return if @voice_bot.nil?

    #  @voice_bot.destroy
    #  @voice_bot = nil
    #  "Left voice channel - **Happy?**"
    #end


    ## Pause playing sound
    #@discord_cbot.command(:pause) do |e|
    #  @voice_bot.pause
    #  "**Stopped - Use !unpause to resume Playback**"
    #end

    ## Stops playing sound
    #@discord_cbot.command(:stop) do |e|
    #  @loop_playback = false if @loop_playback

    #  @stop_playing = true
    #  @voice_bot.stop_playing true
    #  "Stopped playback."
    #end

    ## UnPause playing sound
    #@discord_cbot.command(:unpause, description: 'Resumes playback of song') do |e|
    #  @voice_bot.continue
    #  "**Resumed playback.**"
    #end

    ## Skip song for n seconds
    #@discord_cbot.command(:fwd, description: 'Forward song for given seconds') do |e, *args|
    #  secs = args[0].to_f

    #  @voice_bot.skip secs
    #  "**Skipped song for #{secs} Seconds.**\nI didn't like this part too xD"
    #end

    ## Set or get volume of playback
    #@discord_cbot.command(:vol, description: 'To adjust volume', usage: '!vol 0-100') do |e,*args|
    #  return @discord_cbot.send_message(e.channel.id, "Please use !voice first.") unless @voice_bot

    #  vol = args[0]

    #  if vol.nil?
    #    "Current volume: *#{@voice_bot.volume * 100}*"
    #  else
    #    vol = vol.to_f
    #    vol = 100 if vol > 100
    #    @voice_bot.volume = vol.to_f / 100
    #    "Volume set to #{vol}"
    #  end
    #end

    # plays a sound effect placed in data/sounds directory
    # shows list of available sounds when the list is empty
    #@discord_cbot.command(:pse) do |e, *args|
    #  se_name = args[0]
    #  text_channel = e.channel

    #  if se_name.nil?
    #    files = Dir.glob File.join(SOUND_EFFECTD_ROOT, '*.mp3')
    #    sounds_list = files.join("\n").gsub(sounds_dir,'').gsub('.mp3','')
    #    p sounds_list
    #    "**Available Sounds:**\n\n#{sounds_list}"
    #  else
    #    return @discord_cbot.send_message(text_channel.id, "Please use !voice first.") unless @voice_bot
    #    return @discord_cbot.send_message(text_channel.id, "Stop music first..") if @voice_bot.isplaying?

    #    sound_path = File.join SOUND_EFFECTD_ROOT, "#{se_name}.mp3"
    #    @voice_bot.play_file sound_path
    #    nil
    #  end

    #end

    #play_usage = '!play url of Soundcloud/Youtube or search term'
    #play_description = 'Plays Soundcloud or Youtube Songs. Can search Soundcloud too'
    #@discord_cbot.command(:play, description: play_description, usage: play_usage) do |e, *args|
    #  url = args[0]
    #  text_channel = e.channel
    #  voice_bot = e.voice
    #  puts "URL Given to Play: #{url.inspect}\n"
    #  puts "VoiceBot: #{voice_bot.inspect}\n"
    #  voice_bot.play_file './theme_star_wars.mp3'


    #  # make sure we have a valid voice_bot
    #  return text_channel.send_temporary_message(':x: Please sit in a Voice Channel and use !voice first', 5) unless @voice_bot


    #  # no url specified, resume song playing
    #  if url.nil?
    #    puts "Url is nil"
    #    @stop_playing = false
    #    text_channel.send_message ':musical_note: Resumed playback...' and return nil
    #    play_songs text_channel
    #  end

    #  puts "Sont details = nil"
    #  songs_details = nil

    #  puts "Returning, url" + url
    #  return
    #  # 's' as first param means searched song play
    #  if url == 's'
    #    "Playing Soundcloud Song"
    #    n = args[1].to_i - 1
    #    text_channel.send_message ':notes: Downloading song... Please wait.'
    #    songs_details = [download_sc_track_mp3(sc_client, @searched_songs_queue[n])]
    #  elsif url.include? 'soundcloud'
    #    text_channel.send_message ':notes: Downloading SoundCloud song... Please wait.'
    #    songs_details = download_sc_mp3 url
    #  elsif url.include? 'youtube'
    #    text_channel.send_message ':notes: Downloading Youtube song... Please wait.'
    #    songs_details = download_yt_mp3 url
    #  else
    #    # not a proper URL so we search
    #    q = args.join ' '
    #    @searched_songs_queue = sc_search q
    #    text_channel.send_message ":mag_right: Search Results: (use !play s n)\n#{format_songs_for_printing @searched_songs_queue}"
    #    return nil
    #  end
    #
    #  return @discord_cbot.send_message(text_channel.id, 'Some error, please contact creator of this Bot.') if songs_details.nil?
    #
    #  # add songs to queue, and play first song
    #  queue_songs songs_details
    #  play_songs text_channel
    #end

    #@discord_cbot.command(:q, description: 'Current queued songs, shuffle, loop or clear', usage: "\n!q\n!q shuffle\n!q loop\n!q clear") do |e, *args|
    #  param = args[0]

    #  if param == 'shuffle'
    #    @songs_queue.shuffle!
    #    'Shuffled song Queue.'
    #  elsif param == 'loop'
    #    # toggle looping playback
    #    @loop_playback = !@loop_playback
    #    @loop_playback ? 'Looping current track' : 'Not looping current track now'
    #  elsif param == 'clear'
    #    @songs_queue = []
    #    @voice_bot.stop_playing true
    #    'Cleared song queue'
    #  else
    #    ret = "**Song Queue:**\n\n" + format_songs_for_printing(@songs_queue)
    #  end
    #end

    ## skips current song and plays next in queue
    #@discord_cbot.command(:skip, description: 'Skips current song and plays next.', usage: '!skip') do |e|
    #  text_channel = e.channel
    #  song_details = @songs_queue.first

    #  return unless song_details # return if no song present in queue

    #  @loop_playback = false if @loop_playback

    #  # stop current song, play_songs will automatically
    #  # remove this song from queue and start next song
    #  @voice_bot.stop_playing

    #  "Skipped **#{song_details[:name]}** on request of <@#{e.user.id}>"
    #end

    ## plays next song in queue
    #def play_songs discord_text_channel
    #  song_details = @songs_queue.first

    #  # Notify if no more songs left.
    #  return discord_text_channel.send_message 'Song queue exhausted...' unless song_details

    #  # return if a song is already being played
    #  return discord_text_channel.send_temporary_message ':musical_note: Already playing, Song queued...', 5 if @voice_bot.isplaying?

    #  # loop through all songs playing them until queue finishes
    #  # play_file is a blocking call
    #  while @songs_queue.length > 0
    #    song_details = @songs_queue.first

    #    puts "Song queue now: #{@songs_queue.inspect}\n-------\n"

    #    send_msg discord_text_channel.id, ":musical_note: Now Playing **#{song_details[:name]}** - #{song_details[:duration]}"

    #    # catch exceptions so we don't break player if some error occurs in play_file
    #    begin
    #      mp3_path = song_details[:local_path]

    #      song_details[:started_at] = Time.now
    #      @voice_bot.play_file mp3_path

    #      # keep playing same song while @loop_playback is true
    #      if @loop_playback
    #        while @loop_playback
    #          @voice_bot.play_file mp3_path
    #        end
    #      end
    #    rescue Exception => e
    #      puts "\nExcception playing file #{mp3_path}\nException: #{e.inspect}"
    #    end
    #    #send_msg discord_text_channel.id, "Finished playing **#{song_details[:name]}**  - #{song_details[:duration]}"

    #    # if playback was stopped wait till it's resumed again and play same song from start
    #    if @stop_playing
    #      while @stop_playing
    #        sleep 1
    #      end
    #    else
    #      # song finished, drop it from queue, and play next song
    #      @songs_queue.shift
    #    end

    #  end # while @songs_queue.length > 0
    #end

  end

  private
  def queue_songs songs_details = []
    @songs_queue += songs_details

    puts "Added these songs: " + songs_details.inspect
  end

  def send_msg chanid, text
    @discord_cbot.send_message chanid, text
  end

  # take songs array of hashes in our format
  # and pretty formats them for printing
  def format_songs_for_printing songs_list
    song_names_with_info = songs_list.map.with_index do |song_detail,i|
      queue_details = "#{i+1} - **#{song_detail[:name]}** - "

      # calculate song played duration if we have started_at information
      if song_detail[:started_at]
        time_delta = Time.now - song_detail[:started_at]
        time_played = pretty_time time_delta * 1000
        queue_details += "#{time_played}/"
      end

      queue_details += "#{song_detail[:duration]}"
    end

    song_names_with_info.join "\n"
  end
end

puts "Creating Bot Instance"
bot = Obra.new
puts "Running bot..."
bot.run
