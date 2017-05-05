################################################################################

KAFKA_TOPIC=test
SLEEP_SECONDS=2
LOG_OPTIONS=-t -f
DATABASE_NAME=makefile_microservices
DATABASE_MIGRATION_PATH=clojure-leiningen-rest-service/test-resources/test-schema.sql
POSTGRES_IMAGE=postgres:9.5-alpine
KAFKA_IMAGE=wurstmeister/kafka:0.10.2.0
KOPS_CLUSTER_NAME=kube.nanomanage.com
KOPS_STATE_STORE=s3://kube-nanomanage-com-state-store
AWS_REGION=us-east-1
AWS_ZONES=us-east-1a,us-east-1b,us-east-1c

################################################################################

default: all

# Run all tests
.PHONY: check
check:
	cd clojure-leiningen-rest-service && lein test
	cd java-dropwizard-rest-service && mvn test
	cd java-dropwizard-stream-processor && mvn test

# Delete all built artifacts, both language builds and docker images
.PHONY: clean
clean:
	-docker-compose --project-name=makefile_microservices down --rmi local
	-cd clojure-leiningen-rest-service && lein clean
	-cd java-dropwizard-rest-service && mvn clean
	-cd java-dropwizard-stream-processor && mvn clean

# Reset all docker/docker-compose local state
.PHONY: distclean
distclean: clean
	-docker-compose --project-name=makefile_microservices rm -f -v
	-docker network rm makefile_microservices

# Clojure project build via Leiningen
clojure-leiningen-rest-service/target/clojure-leiningen-rest-service-*-standalone.jar:
	cd clojure-leiningen-rest-service && lein uberjar

# Java project build via Maven
java-dropwizard-rest-service/target/java-dropwizard-rest-service-*.jar:
	cd java-dropwizard-rest-service && mvn package

# Java project build via Maven
java-dropwizard-stream-processor/target/java-dropwizard-stream-processor-*.jar:
	cd java-dropwizard-stream-processor && mvn package

# Build all docker images
.PHONY: all
all: clojure-leiningen-rest-service/target/clojure-leiningen-rest-service-*-standalone.jar java-dropwizard-rest-service/target/java-dropwizard-rest-service-*.jar java-dropwizard-stream-processor/target/java-dropwizard-stream-processor-*.jar
	docker-compose --project-name=makefile_microservices build

# Create docker external network used by non-compose-managed containers to connect to compose-managed services
.PHONY: _network
_network:
	-docker network create makefile_microservices

# Run all services via docker-compose
.PHONY: _run
_run: _network
	docker-compose --project-name=makefile_microservices up -d

# Run all services via docker-compose
.PHONY: _sleep
_sleep:
	sleep $(SLEEP_SECONDS)

# Create postgres database via psql
.PHONY: database-bootstrap
database-bootstrap: all _run _sleep
	-docker run --network makefile_microservices --rm -it --entrypoint createdb $(POSTGRES_IMAGE) -h postgres -U postgres $(DATABASE_NAME)

# Migrate postgres database via psql
.PHONY: database-migrate
database-migrate: database-bootstrap
	-docker run --network makefile_microservices --rm -i --entrypoint psql $(POSTGRES_IMAGE) -h postgres -U postgres -d $(DATABASE_NAME) < $(DATABASE_MIGRATION_PATH)

# Run, bootstrap, migrate, and then display status of all services via docker-compose
.PHONY: run
run: database-migrate
	docker-compose --project-name=makefile_microservices ps

# Stops the write_service, and launches a Clojure REPL instead
.PHONY: repl
repl: run
	docker-compose stop write_service
	cd clojure-leiningen-rest-service && lein repl :headless

# Stop the services (but preserve the images and state)
.PHONY: stop
stop:
	docker-compose --project-name=makefile_microservices stop

# Tail the docker-compose logs
.PHONY: logs
logs:
	docker-compose --project-name=makefile_microservices logs $(LOG_OPTIONS)

# Run psql in a docker container, connected to the postgres service
.PHONY: psql
psql:
	docker run --network makefile_microservices --rm -it --entrypoint psql $(POSTGRES_IMAGE) -h postgres -U postgres -d $(DATABASE_NAME) $(args)

# Tail KAFKA_TOPIC ("test" by default) via kafka-console-consumer in a docker container
.PHONY: kafka-console-consumer
kafka-console-consumer:
	docker run --network makefile_microservices --rm -it --entrypoint /opt/kafka/bin/kafka-console-consumer.sh $(KAFKA_IMAGE) --bootstrap-server kafka:9092 --topic $(KAFKA_TOPIC) $(args)


# Build a Kubernetes cluster via kops
.PHONY: provision
provision:
	kops create cluster --cloud=aws --node-count=3 --node-size=t2.small --zones $(AWS_ZONES) --master-size=t2.large --master-zones $(AWS_ZONES) --name $(KOPS_CLUSTER_NAME) --state $(KOPS_STATE_STORE) --ssh-public-key=~/.ssh/id_rsa.pub --yes

# Push Docker images to ECR
.PHONY: push
push: all
	docker-compose --project-name=makefile_microservices push

# Deploy the services to Kubernetes
.PHONY: deploy
deploy: push
	kompose up
