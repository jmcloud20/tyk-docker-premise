#!/bin/bash
# Author: Joseph M. Garcia
# Date: 12/05/2019
# Description: docker setup tyk container.
# Date Modified: 12/05/2019

# V2
# Segregated process so restart can happen without redoing everything.

# Notes
# Make sure port 6379 is not being used in local machine.


# Process


all(){
	echo -- Executing all
	clear
	stopAllContainers
	createNetwork
	createRedis
	createTykGateway
	createMongoDB
	createTykDashboard
	createTykPump
	checkNetwork
}

stopAllContainers(){
	docker stop tyk-redis
	docker stop tyk-gateway
	docker stop tyk-mongo
	docker stop tyk-dashboard
	docker stop tyk-pump
}

createNetwork(){
	echo -- Create network
	docker network rm tyk
	docker network create tyk
	docker network ls
}

createRedis(){
	# docker pull redis:latest
	echo -- Setup redis dependency
	docker stop tyk-redis
	echo -- create redis volume
	docker volume create redisdb

	#docker pull redis:5.0.7-alpine
	docker run -d --rm --name tyk-redis --network tyk -p 6379:6379 -v redisdb:/data redis:latest
}

createTykGateway(){
	echo -- Pull tyk gateway.
	docker stop tyk-gateway
	docker pull tykio/tyk-gateway:latest

	# echo -- Copy downloaded configuration from tyk-github to mounted directories.
	# Change copy location to local directory. Current is set to windows local D: drive
	# cp ./tyk.standalone.conf d:/tmp/tyk-poc/tyk-gateway/conf
	# cp ./tyk.with_dashboard.conf /d/tmp/tyk-poc/tyk-gateway/conf

	# Headless mode run tyk. Change volume location to local directory. Current is set to windows local D: drive
	# docker run -d \
	#  --name tyk_gateway \
	#  --network tyk \
	#  -p 8080:8080 \
	#  -v d:/tmp/tyk-poc/tyk-gateway/conf/tyk.standalone.conf:/opt/tyk-gateway/tyk.conf \
	#  -v d:/tmp/tyk-poc/tyk-gateway/apps:/opt/tyk-gateway/apps \
	#  tykio/tyk-gateway:latest

	echo -- Tyk gateway pro installation
	docker run -d --link tyk-redis:tyk-redis \
		--name tyk-gateway \
	        --rm \
		--network tyk \
		-p 8080:8080 \
		-v d:/tmp/tyk-poc/tyk-gateway/tyk.conf:/opt/tyk-gateway/tyk.conf \
		tykio/tyk-gateway:latest > /dev/null

	echo -- Check gateway if up and running
	curl http://localhost:8080/hello -i
}

createMongoDB(){
	echo -- Create mongoDB docker instance.
	docker stop tyk-mongo
	echo -- Create docker volume mongoDB
	docker volume create mongodb
	echo -- Create mongoDB container.
	docker run -d \
		--rm \
		--name tyk-mongo \
		-p 27017:27017 \
		-v mongodb:/data/db \
		--network tyk \
		mongo:latest > /dev/null
}

createTykDashboard(){
	echo -- Create TYK dashboard instance 
	# docker stop tyk_dashboard
	docker run -d --link tyk-redis:tyk-redis --link tyk-mongo:tyk-mongo --link tyk-gateway:tyk-gateway \
		--rm \
	    	--name tyk-dashboard \
		-p 3000:3000 \
		-v d:/tmp/tyk-poc/tyk-dashboard/tyk_analytics.conf:/opt/tyk-dashboard/tyk_analytics.conf \
		--network tyk \
		tykio/tyk-dashboard > /dev/null
}

createTykPump(){
	echo -- Setup tyk pump to fill dashboard data
	docker stop tyk-pump 	
	docker run -d --link tyk-redis:tyk-redis --link tyk-mongo:tyk-mongo --network tyk \
		--rm \
		--name tyk-pump \
		-v d:/tmp/tyk-poc/tyk-pump/pump.conf:/opt/tyk-pump/pump.conf \
		tykio/tyk-pump-docker-pub > /dev/null
}

checkNetwork(){
	docker network inspect tyk
}

functionMenu(){
	case $1 in
		a) echo Selected restart all.
			all;;
		cn) echo Selected check docker network
			checkNetwork;;
		crn) echo Selected recreate tyk network
			createNetwork;;
		tg) echo Selected recreate tyk gateway
			createTykGateway;;
		td) echo Selected recreate tyk dashboard
			createTykDashboard;;
		md) echo Selected recreate monggoDB
			createMongoDB;;
		rd) echo Selected recreate redis
			createRedis;;
		p) echo Selected recreate pump
			createTykPump;;
		sa) echo Selected stop all containers
			stopAllContainers;;
		*) echo Invalid selection.
	esac
}



functionMenu $1

# Install vim to update files and ping
# apt-get update && apt-get install vim && apt-get install iputils-ping && apt-get install net-tools && apt-get install procps
