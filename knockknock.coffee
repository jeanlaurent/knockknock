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
	scan : (host, callback) ->
		exec "nmap -O #{host.ip} --host-timeout 3000", (error,stdout) ->
			# range check on regexp is needed
			result =
				localName : stdout.match(new RegExp /Nmap scan report for (.*) \((.*)\)/i)[1]
				macManufacturer : stdout.match(new RegExp /Mac Address: (.*) \((.*)\)/i)[2]
				deviceType : stdout.match(new RegExp /Device type: (.*)/i)[1]
				os : stdout.match(new RegExp /Running: (.*)/i)[1]
				osDetails : stdout.match(new RegExp /OS details: (.*)/i)[1]
			callback host, result

class Host
	constructor: (@ip, @mac) ->

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