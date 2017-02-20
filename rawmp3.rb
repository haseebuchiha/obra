ROOT_URL = 'data/sounds/raw'

def download_raw_mp3 url
  song_name_parts = url.split('/')
  ret_data = {local_path: song_file_path, name: song_name}
end

download_raw_mp3 ARGV[0]
