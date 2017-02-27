require_relative 'common_helper'
require_relative '../config'

module SoundCloudHelper
  include GenericHelper

  CURRENT_DIR = File.dirname(__FILE__)
  ROOT_DIR = "#{CURRENT_DIR}/../../data/sounds/soundcloud"

  # takes soundcloud URL of a song or a Playlist
  # downloads the tracks and
  # returns array of hashes, with song details
  def download_soundcloud_mp3 sc_url
    sc_config = $config[:soundcloud]
    puts "Creating soundcloud Client with: #{sc_config.inspect}\nDownload URL: #{sc_url}\n"

    sc_client = SoundCloud.new sc_config

    # call the resolve endpoint with a track url
    begin
      track = sc_client.get('/resolve', url: sc_url)
    rescue Exception => e
      puts "Exception: #{e.inspect}\n"

      # return if single song, keep going in case of playlist
      # because one or more tracks give exception when creator
      # of them mark them as private but most do get downloaded
      return nil unless track.kind == 'playlist'
    end

    # return song details array
    ret = []

    # if this is a playlist url, enquee all songs
    if track.kind == 'playlist'
      track.tracks.each do |t|
        ret << save_track(sc_client, t)
      end
    else
      ret << save_track(sc_client, track)
    end

    p ret
    return ret
  end

  # takes soundcloud track object and saves it locally in ROOT_DIR
  #  and returns track info as needed by our player
  def save_track sc_client, track
    save_path = File.join ROOT_DIR, "#{track.id}.mp3"
    download_track_mp3 sc_client, track, save_path unless File.exists?(save_path)
    { name: track.title, length: track.duration, duration: pretty_time(track.duration), local_path: save_path }
  end

  # give sound cloud track and local save_path, it will download and save song as mp3
  def download_track_mp3 sc_client, track, save_path
    stream_url = sc_client.get(track.stream_url, :allow_redirects => true)

    open save_path, 'w' do |io|
      puts "Downloading sound cloud mp3 chunks..."
      io.write stream_url
    end
  end

end


#----------------
#  DEPRICIATED  #
#----------------
def dl_old_form_mechanize sc_url
  # Converts Song urls with playlist info at the end like this
  #   https://soundcloud.com/daso/daso-meine?in=blackdivine/sets/party
  # To this
  #   https://soundcloud.com/daso/daso-meine
  song_url_end = sc_url.index('?')
  sc_url = sc_url[0..song_url_end-1] if song_url_end

  # calculate proper mp3 filename to save
  sc_url_parts = sc_url.split('/')

  # prettify song-name-like-this to Spaces and Cap first Alphabet of every word
  song_name = sc_url_parts[-1]
  song_name = song_name.gsub('-',' ').gsub(/\w+/,&:capitalize)

  uploader_name = sc_url_parts[-2]

  song_file_name = sanitize_filename "#{uploader_name}_#{song_name}.mp3"
  song_file_path = File.join ROOT_DIR, song_file_name

  ret_data = {local_path: song_file_path, name: song_name}

  if File.exists?(song_file_path)
    puts 'Song already downloaded...'
    return ret_data
  end

  m = Mechanize.new
  m.get('http://9soundclouddownloader.com/') do |home_page|
    # submit form with soundcloud song URL
    dl_page = home_page.form_with(:action => '/download-sound-track') do |f|
      f['sound-url'] = sc_url
    end.click_button

    #dl_page.links.each do |l|
    #  puts l.inspect
    #end

    # get mp3 URL from the Download button link
    dl_page.link_with(class: 'expanded button') do |mp3_dl_link|
      agent_string = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/55.0.2883.87 Chrome/55.0.2883.87 Safari/537.36'
      dl_link = mp3_dl_link.uri
      puts "\nSoundcloud MP3 Download Link: #{dl_link.to_s}\n"

      #dl_link = 'https://cf-media.sndcdn.com/7uxUnSLHBu3x.128.mp3?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiKjovL2NmLW1lZGlhLnNuZGNkbi5jb20vN3V4VW5TTEhCdTN4LjEyOC5tcDMiLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE0ODU5NDA3OTN9fX1dfQ__&Signature=Y6MdOhA1duKxEyuViMxHYYH5DDpAj5DDByS0h0X4CmlMKF9ui4QuUQpzFwOOK24xGAuh87Sfqj5EV7BEfSS-Nnr03n53twchQRkefxSDv2o87TSuuKgnGpVSnSxRrf9cwzFKxede9mc22Wy9VjjbBBY-Sw-dJDz5BKaTqjFX33Bd5OwmlKAGFAg2YtqAkNvLl3DKLxMkpjAYKw59RuuodgXFLqD9lTrKh0OcC3fOH07mXdTMT~UTgFM8i~HfsEHnweVywHN8IbtOLNwXCNvZX-e9SIHGiaDxYgMfgu1lhfiudr7L1h0ACC2dkQ0dxzk~5zLBIwpHqD6u0uM3zADe8Q__&Key-Pair-Id=APKAJAGZ7VMH2PFPW6UQ'
      puts "Downloading song to #{song_file_path}..."
      dl_cmd = "wget --no-check-certificate \"#{dl_link}\" -O #{song_file_path}"
      p dl_cmd
      system dl_cmd
      puts "Downloaded song to #{song_file_path}..."

      return ret_data
    end
  end
end
