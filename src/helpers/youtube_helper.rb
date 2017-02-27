require 'json'
require_relative 'common_helper'

module YoutubeHelper
  CURRENT_DIR = File.dirname(__FILE__)
  ROOT_DIR = "#{CURRENT_DIR}/../../data/sounds/youtube"

  def download_youtube_mp3 yt_url
    puts "In download_youtube_mp3 with youtube URL: #{yt_url}\n"
    cmd = 'youtube-dl -i --max-filesize 150m -x --audio-format "mp3" -o "' + ROOT_DIR + '/%(id)s.%(ext)s" '
    cmd += '--write-info-json --no-post-overwrites --no-part -w ' + yt_url 

    # return song details array
    ret = []

    # youtube-dl will download all songs and place json files,
    puts "\nRunning youtube-dl command:\n#{cmd}\n"
    `#{cmd}`

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
