# Load up our imports
irc = require 'irc'
settings = require '../settings'
_ = require 'underscore-contrib'
$ = require 'cheerio'
request	= require 'request'
async = require 'async'

# Connect to the IRC Server
bot = new irc.Client settings.server, settings.botName, settings
console.log "#{settings.botName} connecting to #{settings.server} #{settings.channels} ..."

clients = ['tucker', 'kevinwelcher']
channels = settings.channels
 
# If a private message is sent, check if we are required to join or part a channel
bot.addListener 'pm', (from, to, message) ->
	text = message.args[1]
	if join = text.match(/join\s+(#?\w+)/)
		if join[1] != '#' then join[1] = '#' + join[1]
		bot.join join[1]

	if part = text.match(/part\s+(#?\w+)/)
		if part[1] != '#' then part[1] = '#' + part[1]
		bot.part part[1]
		
	translateEmoji text, from

# Whenever you get a ping, check where your clients are and follow (stalk) them 
bot.addListener 'ping', (server) ->
    follow()
	
# Whenever you join the server also stalk your clients, because you're like that, emojibot.
bot.addListener 'registered', (server) ->
    follow()

# Perform a whois on whatever clients you are watching and join the channel
# they are apart of
follow = () -> 
	for nick in clients 
		bot.whois nick, (info) ->
			console.log info
			return unless info.channels
			for channel in info.channels
				# strip out their mod status
				channel = channel.slice 1 if ((channel.indexOf '@') == 0)
				if channel not in channels
				   channels.push channel
				   bot.join channel

# Event listener for all IRC actions, currently we are just checking if it either
# an actiion (/me) or regular message in channel. Both are encapsulated by the 
# 'PRIVMSG' command. 
bot.addListener 'raw', (message) -> 
	if message.command is 'PRIVMSG' and message.args and message.args.length >= 2
		translateEmoji message.args[1], message.args[0]
   
# UTF 16 Dicitates that Unicode Characters above 65,534 (0xFFFF)
# be represented in two shorts. Where the first short is within [0xD800, 0xDBFF]
# and the second within [0xDC00, 0xDFFF], then I use math to give me the full
trueCode = (str, i) => 
	code = str.charCodeAt(i)
	if 0xD800 <= code && code <= 0xDBFF
		hi = code;
		low = str.charCodeAt i+1
		if isNaN low 
			return console.log "Not sure how you typed that character..."

		# black magic
		code = ((hi - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000

	if 0xDC00 <= code && code <= 0xDFFF
		return	false; # already handled low
	return code;

# A factory of sorts, essentially closes the unicode into the async function. The
# async function wraps the request call so that it can be called in series.
fetchUnicode = (code) => 
	(callback) =>  # async function signature
		request "http://shapecatcher.com/unicode_info/#{code}.html", (err, res, html) ->
			if err or res.statusCode is 404
				return callback null, undefined
			parsedHTML = $.load(html)
			image = "http://shapecatcher.com" + parsedHTML('article img').attr('src')

			$text = parsedHTML('article').children().remove();
			description = parsedHTML('article').text().trim().split('\n')[0].split(':')[1].trim()
			return callback null, {description: description, image: image}
	
# The same sort of factory, but this time responsible for returning the image if it exisits
fetchGit = (emoji) => 
	emoji = encodeURIComponent emoji # +1 TO %2B1
	(callback) => 
		request "http://www.emoji-cheat-sheet.com/graphics/emojis/#{emoji}.png", (err, res, html) ->
			if err or res.statusCode is 404 
				return callback null, undefined
			return callback null, {description: "http://www.emoji-cheat-sheet.com/graphics/emojis/#{emoji}.png"}
	
	
# The workhouse method of this bot. It reads each character, determines if it's an emoji, 
# and creates a request to shapecatcher for more details. Finally it runs the requests 
# in series, concat'ing the results in the order they were made.
translateEmoji = (text, channel, drawMode) =>
	drawMode = false
	funcs = []
	
	if (text.indexOf "emojibot") == 0
		drawMode = true
	
	# check for github emojis 
	gitMojis = (text.match /:[+-]?(\w+):/g) || [];
	for match in gitMojis 
		funcs.push fetchGit match.replace /:/g, ''
	
	# check for unicode emojis in text
	for i in [0..text.length]
		code = trueCode text, i

		# code is considered an emoji, pictograph, transport, or alchemical symbol
		if code >= 0x1F300 && code <= 0x1F77F
			funcs.push fetchUnicode code 
 	
	# apply all requests 
	async.series funcs, (err, res) => 
		message = _.reduce(res, (str, emoji) =>
			if emoji
				str += "["
				if drawMode && emoji.image
					str += " #{emoji.image} "
				else 
					str += " #{emoji.description} " 
				str += "]"
		, '' );
		bot.say channel, message
		
# because emojibot is titanium, he never breaks but if he does he fixes himself
bot.addListener 'error', (message) ->
    console.log 'error: ', message