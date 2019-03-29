TODO:
===
* ~~Handle soundcloud URLs with playlist name in the end gracefully~~
* ~~Parse Soundcloud playlist and add songs to queue~~
* ~~Implement Youtube playback~~
* ~~Add duration information in Song Queue~~
* ~~Persist volume (when bot leaves and re-enters voice chan the volume resets)~~
* ~~Track to what duration song was played and display song played duration in queue command.~~

# How to Install

### Make Folders
* data/sounds/youtube
* data/sounds/soundcloud
* data/sounds/effects

### Install
* ffmpeg
* libsodium-dev
* libopus-dev
* [youtube-dl](https://rg3.github.io/youtube-dl/)
* mongodb
* [rvm](http://rvm.io)

### Configuration
* Rename config.sample to config.rb
* Fill in relevant values.

### Running
* cd into root dir
* install ruby as hinted by Rvm
* bundle install
* $touch production (if running bot in production)
* $./run
