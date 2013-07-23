# Load up our imports
irc       = require 'irc'
config    = require '../settings'
_         = require 'underscore-contrib'

# Connect to the IRC Server
bot = new irc.Client settings.server, settings.botName, settings
console.log "#{settings.botName} connecting to #{settings.server} #{settings.channels} ..."

# Say something in the channel
act = (actions, channel, odds) ->
  if Math.random() < odds
    bot.action channel, actions[Math.floor(Math.random() * actions.length)]

# Return the first reaction object
hasReaction = (text) ->
  _.find reactions, (reaction) ->
    _.intersection(text.toLowerCase().split(' '), reaction.actions).length


# If a private message is sent, check if we are required to join a channel
bot.addListener 'pm', (from, to, message) ->
  if join = message.args[1].match(/join\s+(#?\w+)/)
    if join[1] != '#' then join[1] = '#' + join[1]
    bot.join join[1]


# For all messages, add them to our history  and check if we need to act on it
bot.addListener 'message', (username, channel, text, message) ->
  text = text.toLowerCase()
  directlyAddressed = ~text.indexOf settings.botName.toLowerCase()

  # Puppy should randomly respond to random messages
  if not directlyAddressed then return act(generic, channel, 0.001)

  # Puppy should respond most of the time is some one uses a keyword
  reaction = hasReaction(text)
  if reaction then return act(reaction.response, channel, 0.85)

  # Puppy responds sometimes when people address him by name
  act(generic, channel, 0.6)


# Every hour, have a chance to do something
setInterval _.partial(bored, act, '#willowtree', 0.05), (1000 * 60 * 60)
