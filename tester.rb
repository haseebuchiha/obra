# Used to quicly test from IRB as it returns a cbot
require 'discordrb'

require './config'
require './soundcloud'
require './helper'

module ObraTest
  # tester would always run in dev
  ENV = :development

  DISCORD_CBOT_SETTINGS = {
    name: 'One Bot to Rule Them All',
    fancy_log: true,
    advanced_functionality: true, #TODO: Find out what it does
    prefix: '!',
  }.merge!($config[ENV])

  def cbot
    discord_cbot = Discordrb::Commands::CommandBot.new DISCORD_CBOT_SETTINGS
  end
end
