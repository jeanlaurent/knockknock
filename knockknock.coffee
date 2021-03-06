events = require 'events'
util = require 'util'
fs = require 'fs'
spawn = require('child_process').spawn
exec = require('child_process').exec

class ArpScanner
	scan : (callback) ->
		exec './scripts/knockknock.sh', (error,stdout,stderr) ->
			arphosts = []
			lines = stdout.split '\n'
			for line in lines
				words = line.split ' '
				if words[0].length > 0
					arphosts.push new Host words[0], words[1]
			callback arphosts

class NmapScanner

	match: (stdout,regexp,value) ->
		result = stdout.match(new RegExp regexp)
		return result[value] if result? and result.length > value
		return "???"


	scan : (host, callback) ->
		exec "nmap -O #{host.ip} --host-timeout 3000", (error,stdout) =>
			# range check on regexp is needed
			result =
				localName : @match stdout, /Nmap scan report for (.*) \((.*)\)/i,1
				macManufacturer : @match stdout, /Mac Address: (.*) \((.*)\)/i, 2
				deviceType : @match stdout,/Device type: (.*)/i,1
				os : @match stdout,/Running: (.*)/i,1
				osDetails : @match stdout,/OS details: (.*)/i,1
			callback host, result

class Host
	constructor: (@ip, @mac) ->

class HostDatabase
	constructor: () ->
		try
			@database = JSON.parse fs.readFileSync "database.json","utf-8"
		catch e
			@database = {}

	update: (host) ->
		console.log @database
		for dbHost in @database when host.mac == dbHost.mac
			dbHost = host
		console.log @database

	lookup: (mac) ->
		return host.desc for host in @database when host.mac == mac

	save: () ->
		fs.writeFileSync "database.json", JSON.stringify @database, "utf-8"

class Hosts extends events.EventEmitter
	constructor: () ->
		@hosts = []
		@database = new HostDatabase()
		@on 'new host', @newHost
		@arpScanner = new ArpScanner()
		@nmapScanner = new NmapScanner()

	scan: () ->
		@arpScanner.scan @addAll # dirty, dirty

	add: (ip, mac) =>
		newHost = new Host ip, mac
		newHost.name = @database.lookup mac
		@hosts.push newHost
		@nmapScanner.scan newHost, (newHost, result) ->
			console.log "nmap fo #{newHost.ip}"
			console.log result
		@emit 'new host', newHost

	addAll: (someHosts) =>
		console.log "found #{someHosts.length} devices in your local network."
		for host in someHosts
			@add host.ip, host.mac

	updateHost: (updatedHost, nmapReport) =>
		for host in @hosts when host.mac == updatedHost
			host = updatedHost

	lastHost: () ->
		@hosts[@hosts.length-1]

	newHost: (host) ->
		id = "unknown !"
		id = "#{host.name}" if host.name?
		console.log "Hey we got a new host #{host.ip} / #{host.mac} => #{id}"


new Hosts().scan()
