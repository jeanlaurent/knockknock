events = require 'events'
util = require 'util'
fs = require 'fs'

class Host
	constructor: (@ip, @mac) ->
		@name = ""

class HostDatabase
	constructor: () ->
		@database = JSON.parse fs.readFileSync "database.json","utf-8"

	update: (host) ->
		console.log @database
		for dbHost in @database when host.mac == dbHost.mac
			dbHost = host
		console.log @database
		
	lookup: (mac) ->
		return host.desc for host in @database when host.mac == mac

class Hosts extends events.EventEmitter
	constructor: () ->
		@hosts = []
		@database = new HostDatabase()
		@on 'new host', @newHost

	processStdin: () ->
		stdin = process.openStdin(); 
		process.stdin.setEncoding 'utf8'

		process.stdin.on 'data', (chunk) =>
			lines = chunk.split '\n'
			for line in lines
				words = line.split ' '
				if words[0].length > 0
					@add words[0], words[1]

	add: (ip, mac) ->
		newHost = new Host ip, mac
		newHost.name = @database.lookup mac
		@hosts.push newHost
		@emit 'new host', newHost

	lastHost: () ->
		@hosts[@hosts.length-1]

	newHost: (host) ->
		id = "unknown !"
		id = "#{host.name}" if host.name?
		console.log "Hey we got a new host #{host.ip} / #{host.mac} => #{id}"

new Hosts().processStdin()