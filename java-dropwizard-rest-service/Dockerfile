FROM java:8-alpine
MAINTAINER Bobby Calderwood <bobby@example.com>

ENV JAVA_OPTS=""

RUN mkdir -p /opt
ADD target/java-dropwizard-rest-service-*.jar /opt/app.jar

EXPOSE 8080

CMD java ${JAVA_OPTS} -jar /opt/app.jar
