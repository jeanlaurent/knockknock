events = require 'events'
util = require 'util'
fs = require 'fs'
spawn = require('child_process').spawn
exec = require('child_process').exec

class ArpScan
	scan : (callback) ->
		console.log '-> arp scan'
		exec './scripts/knockknock.sh', (error,stdout,stderr) ->
			arphosts = []
			lines = stdout.split '\n'
			for line in lines
				words = line.split ' '
				if words[0].length > 0
					arphosts.push new Host words[0], words[1]
			callback arphosts
			
class NmapScan
	constructor: (@host) ->
		@data=""
	
	scan : ->
		@nmap = spawn('nmap',['-O',@host.ip,'--host-timeout','3000'])
		console.log "launching nmap with #{@nmap.pid}"
		@nmap.stdout.on 'data', (data) =>
			@data = "#{@data}#{data.toString()}"
		@nmap.on 'exit', (code) =>
			console.log "================"
			console.log "scan for #{@host.name}" 
			console.log "data received : "
			console.log "#{@data}"
			console.log "exit code is : #{code}"
			@nmap.stdout.end();


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

	scan: () ->
		new ArpScan().scan @addAll # dirty, dirty

	add: (ip, mac) =>
		newHost = new Host ip, mac
		newHost.name = @database.lookup mac
		@hosts.push newHost
		# new NmapScan(newHost).scan()	
		@emit 'new host', newHost

	addAll: (someHosts) =>
		for host in someHosts
			@add host.ip, host.mac

	lastHost: () ->
		@hosts[@hosts.length-1]

	newHost: (host) ->
		id = "unknown !"
		id = "#{host.name}" if host.name?
		console.log "Hey we got a new host #{host.ip} / #{host.mac} => #{id}"


new Hosts().scan()