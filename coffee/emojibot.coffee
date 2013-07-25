# Load up our imports
irc       = require 'irc'
settings   = require '../settings'
_         = require 'underscore-contrib'
jsdom = require('jsdom')

# Connect to the IRC Server
bot = new irc.Client settings.server, settings.botName, settings
console.log "#{settings.botName} connecting to #{settings.server} #{settings.channels} ..."

# If a private message is sent, check if we are required to join a channel
bot.addListener 'pm', (from, to, message) ->
  if join = message.args[1].match(/join\s+(#?\w+)/)
    if join[1] != '#' then join[1] = '#' + join[1]
    bot.join join[1]

# UTF 16 Dicitates that Unicode Characters above 65,534 (0xFFFF)
# be represented in two shorts. Where the first short is within [0xD800, 0xDBFF]
# and the second within [0xDC00, 0xDFFF], then math gives you the full 
trueCode = (str, i) => 
	code = str.charCodeAt(i)
	if 0xD800 <= code && code <= 0xDBFF
    	hi = code;
    	low = str.charCodeAt i+1
    	if isNaN low 
    		log "Not sure how you typed that character..."

    	code = ((hi - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000

    if 0xDC00 <= code && code <= 0xDFFF
    	return	false; # already handled low
    return code;

# For all messages, add them to our history  and check if we need to act on it
bot.addListener 'message', (username, channel, text, message) ->
  for i in [0..text.length]
    code = trueCode text, i

    # code is considered an emoji or pictograph
    if code >= 0x1F300 && code <= 0x1F64F
    	done = (err, window) =>
    		$ = window.$
    		image = "http://shapecatcher.com#{$('article img').attr('src')}"
    		$text = $('article').children().remove()
    		description = $('article').text().trim().split('\n')[0].split(':')[1].trim()
    		bot.say	channel, "#{description}"
    	jsdom.env {url: "http://shapecatcher.com/unicode_info/#{code}.html", scripts: ['http://code.jquery.com/jquery-1.6.min.js'], done: done}