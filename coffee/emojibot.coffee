# Load up our imports
irc       = require 'irc'
settings   = require '../settings'
_         = require 'underscore-contrib'

# Connect to the IRC Server
bot = new irc.Client settings.server, settings.botName, settings
console.log settings
console.log "#{settings.botName} connecting to #{settings.server} #{settings.channels} ..."

# If a private message is sent, check if we are required to join a channel
bot.addListener 'pm', (from, to, message) ->
  if join = message.args[1].match(/join\s+(#?\w+)/)
    if join[1] != '#' then join[1] = '#' + join[1]
    bot.join join[1]

# For all messages, add them to our history  and check if we need to act on it
bot.addListener 'message', (username, channel, text, message) ->