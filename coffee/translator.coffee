cheerio = require 'cheerio'
request	= require 'request'

#==============================================================================#
#  Translator 
#     - Responsible for grabbing emojis out of strings and creating functions
#       for getting details about them
#==============================================================================#

# UTF 16 Dicitates that Unicode Characters above 65,534 (0xFFFF)
# be represented in two shorts. Where the first short is within [0xD800, 0xDBFF]
# and the second within [0xDC00, 0xDFFF], then I use math to give me the full
exports.trueCode = trueCode = (str, i) => 
	code = str.charCodeAt(i)
	if 0xD800 <= code && code <= 0xDBFF
		hi = code;
		low = str.charCodeAt i+1
		if isNaN low 
			return console.log "Not sure how you typed that character..."

		# black magic
		code = ((hi - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000

	return false if 0xDC00 <= code && code <= 0xDFFF
	return code;

# A factory of sorts, essentially closes the unicode into the async function. 
# The async function wraps the request call so that it can be called in series.
#
# It's a little clunky because aysnc requires you to always return the result of 
# callback. 
exports.fetchUnicode = fetchUnicode = (code, cache) => 
	(callback) =>  # async function signature
		return callback null, cache[code] if cache[code] 
		request "http://shapecatcher.com/unicode_info/#{code}.html", (err, res, html) ->
			return callback null, undefined if err or res.statusCode is 404
			
			$ = cheerio.load(html)
			image = "http://shapecatcher.com" + $('article img').attr('src')

			$('article').children().remove()
			description = $('article').text().trim().split('\n')[0].split(':')[1].trim()
			
			cache[code] = {description: description, image: image}
			return callback null, cache[code]

# The same sort of factory, but this time responsible for returning the image 
# if it exists
exports.fetchGit = fetchGit = (emoji, cache) => 
	emoji = encodeURIComponent emoji 

	(callback) => 
		return callback null, cache[emoji] if cache[emoji]
		image = "http://www.emoji-cheat-sheet.com/graphics/emojis/#{emoji}.png"
		request image, (err, res, html) ->
			return callback null,  
			if err or res.statusCode is 404 then undefined else 
				cache[emoji] = {description: image}

# given a string message, return an array of integer codes for each emoji 
exports.parseEmojis = parseEmojis = (text) ->
	result = []
	for i in [0..text.length]
		code = trueCode text, i 

		result.push code if code >= 0x1F300 && code < 0x1F77F
	return result

# given a string message, return an array of all :emojis: 
exports.parseGitmojis = parseGitmojis = (text) -> 
	return (text.match /:[+-]?(\w+):/g) or [];