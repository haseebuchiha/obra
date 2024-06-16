
module GiphyHelper
  API_BETA_KEY = 'HQ5v7PG0S370v0HHyCnEZEVWqXatlgXm'
  API_ROOT = 'http://api.giphy.com/v1/'

  def gif_search q
    # limit 100 is max
    search_url = API_ROOT + "gifs/search?q=#{URI.encode_uri_component q}&api_key=#{API_BETA_KEY}&limit=100"
    p search_url

    res = HTTParty.get search_url
    res_json = JSON.parse res.body

    total = res_json['pagination']['count']
    return "No gif found for: *#{q}*" if total == 0

    img = res_json['data'][rand 0..total-1]
    img['images']['fixed_height']['url']
  end
end
