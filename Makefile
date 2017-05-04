default: all

.PHONY: clean
clean:
	-docker-compose --project-name=makefile_microservices down --rmi local
	-cd clojure-leiningen-rest-service && lein clean
	-cd java-dropwizard-rest-service && mvn clean
	-cd java-dropwizard-stream-processor && mvn clean

.PHONY: distclean
distclean: clean
	-docker-compose --project-name=makefile_microservices rm -f -v
	-docker network rm makefile_microservices

clojure-leiningen-rest-service/target/clojure-leiningen-rest-service-*-standalone.jar:
	cd clojure-leiningen-rest-service && lein uberjar

java-dropwizard-rest-service/target/java-dropwizard-rest-service-*.jar:
	cd java-dropwizard-rest-service && mvn package

java-dropwizard-stream-processor/target/java-dropwizard-stream-processor-*.jar:
	cd java-dropwizard-stream-processor && mvn package

.PHONY: all
all: clojure-leiningen-rest-service/target/clojure-leiningen-rest-service-*-standalone.jar java-dropwizard-rest-service/target/java-dropwizard-rest-service-*.jar java-dropwizard-stream-processor/target/java-dropwizard-stream-processor-*.jar
	docker-compose --project-name=makefile_microservices build

.PHONY: network
network:
	-docker network create makefile_microservices

.PHONY: _run
_run: network
	docker-compose --project-name=makefile_microservices up -d

.PHONY: sleep
sleep:
	sleep 5

.PHONY: database-bootstrap
database-bootstrap: all _run sleep
	-docker run --network makefile_microservices --rm -it --entrypoint createdb postgres:9.5-alpine -h postgres -U postgres makefile_microservices

.PHONY: database-migrate
database-migrate: database-bootstrap
	-docker run --network makefile_microservices --rm -i --entrypoint psql postgres:9.5-alpine -h postgres -U postgres -d makefile_microservices < clojure-leiningen-rest-service/test-resources/test-schema.sql

.PHONY: run
run: database-migrate
	docker-compose --project-name=makefile_microservices ps

.PHONY: stop
stop:
	docker-compose --project-name=makefile_microservices stop

.PHONY: logs
logs:
	docker-compose --project-name=makefile_microservices logs -t -f

.PHONY: psql
psql:
	docker run --network makefile_microservices --rm -it --entrypoint psql postgres:9.6-alpine -h postgres -U postgres -d makefile_microservices $(args)

.PHONY: kafka-console-consumer
kafka-console-consumer:
	docker run --network makefile_microservices --rm -it --entrypoint /opt/kafka/bin/kafka-console-consumer.sh wurstmeister/kafka:0.10.2.0 --bootstrap-server kafka:9092 --topic test $(args)
