# Knock Knock... Who's there ?

small hacky script to check which are the devices on your local subnet.

## prerequisite

	arp-scan, nmap, node, coffee-script

## update database

* rename example-database.json to database.json
* fill up database.json with your machines mac & name

## launch

	sudo coffee knockknock.coffee

sudo is needed for arp or nmap scan.
