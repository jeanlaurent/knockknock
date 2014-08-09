# Knock Knock... Who's there ?

small hacky script to check which are the devices on your local subnet.

## prerequisite

	arp-scan(1.8), nmap (6.25), node, coffee-script

On a mac:

	brew install arp-scan
	brew install nmap

## update database

* rename example-database.json to database.json
* fill up database.json with your machines mac & desc

## launch

	sudo coffee knockknock.coffee

sudo is needed for arp or nmap scan.
