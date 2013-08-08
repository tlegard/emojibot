irc = require 'irc'
settings = require '../settings'
{fold} = require 'prelude-ls'
translator = require './translator'
async = require 'async'

# Connect to the IRC Server
bot = new irc.Client settings.server, settings.botName, settings
console.log "#{settings.botName} connecting to #{settings.server} #{settings.channels} ..."

clients = ['tucker', 'kevinwelcher']
channels = settings.channels
 
#==============================================================================#
#  IRC Event Bindings
#    - These handle bind actions on different types of low level IRC actions
#==============================================================================#

# If a private message is sent, check he is required to join or part a channel
bot.addListener 'pm', (from, to, message) ->
	text = message.args[1]
	if join = text.match(/join\s+(#?\w+)/)
		if join[1] != '#' then join[1] = '#' + join[1]
		bot.join join[1]

	if part = text.match(/part\s+(#?\w+)/)
		if part[1] != '#' then part[1] = '#' + part[1]
		bot.part part[1]
		
	translateEmoji text, from

# Emojibot hates to be alone, so when he joins he check to see where all his 
# clients are and jumps in their channel
bot.addListener 'registered', (server) ->
    follow()

# Emojibot also has abadadonment issues, so he'll periodically check where his 
# clients are and join them 
bot.addListener 'ping', (server) ->
    follow()
	
# Event listener for all IRC actions. Currently we are only using this to handle
# an action (/me), but we've constructed the check to handle a regular message 
# as well.  
bot.addListener 'raw', (message) -> 
	if message.command is 'PRIVMSG' and message.args and message.args.length >= 2
		translateEmoji message.args[1], message.args[0]
   
# Emojibot is so strong, he never breaks but if he does he'll let us 
# know and try to keep going 
bot.addListener 'error', (message) -> console.log 'error: ', message

#==============================================================================#
#  Bot Actions
#     - These are thing emojibot does on some type of event 
#==============================================================================#

# Perform a whois on whatever clients you are watching and join their channels
follow = () -> 
	for nick in clients 
		bot.whois nick, (info) ->
			return unless info.channels
			
			for channel in info.channels
				# strip out their mod status
				channel = channel.slice 1 if ((channel.indexOf '@') == 0)
				if channel not in channels
				   channels.push channel
				   bot.join channel

# Essentially emojibot is a sham and offloads all of the translation of on
# the translator module. He even gets it to package up the async requests for
# him;I hope this isn't taxing on their relationship...
translateEmoji = (text, channel) =>
	funcs = []
	drawMode = (text.indexOf "emojibot") is 0
	
	# check for github emojis in the form :smile: 
	gitMojis = translator.parseGitmojis text
	funcs.push translator.fetchGit match.slice 1, -1 for match in gitMojis 
	
	# check for unicode emojis in text
	emojis  = translator.parseEmojis text
	funcs.push translator.fetchUnicode emoji for emoji in emojis
 	
	# apply all requests 
	async.series funcs, (err, res) => 
		stringify = (str, emoji) =>
			return str unless emoji
			
			str += "[ " + (if drawMode and emoji.image 
			then "#{emoji.image}"
			else "#{emoji.description}") + " ]"
				
		message = fold stringify, '', res
		
		bot.say channel, message