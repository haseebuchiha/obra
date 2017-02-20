require 'json'
require './helper'

# https://www.youtube.com/playlist?list=PLC516EA09C1C873CF'
module YoutubeHelper
  ROOT_DIR = 'data/sounds/youtube'
  sound_url = ARGV[0] #'https://soundcloud.com/kristiannairn/kristian-nairn-jan-2017-mix-two' #'https://soundcloud.com/tomac_music/tomac-pablo-artigas' #'https://soundcloud.com/asfandyarkhan/a-sudden-sullen-turn'

  def download_youtube_mp3 yt_url
    cmd = 'youtube-dl -i --max-filesize 150m -x --audio-format "mp3" -o "data/sounds/youtube/%(id)s.%(ext)s" '
    cmd += '--write-info-json --no-post-overwrites --no-part -w ' + yt_url 

    # return song details array
    ret = []

    # youtube-dl will download all songs and place json files,
    p `#{cmd}`

    # we parse them and delete them
    json_files = Dir.glob File.join(ROOT_DIR, '*.json')
    json_files.each do |json_file|
      json = JSON.parse File.read(json_file)
      id = json['id']
      length = json['duration']
      duration = pretty_time (length * 1000)

      # add song details to return object
      ret << {name: json['title'], length: length, duration: duration, local_path: File.join(ROOT_DIR, "#{id}.mp3")}

      # done with file so delete it
      File.delete json_file
    end

    puts "--Youtube download return hash: #{ret.inspect}\n"
    ret
  end

end
