FROM java:8-alpine
MAINTAINER Bobby Calderwood <bobby@example.com>

RUN mkdir -p /opt
ADD target/java-dropwizard-stream-processor-*.jar /opt/app.jar

EXPOSE 8080

CMD ["java", "-jar", "/opt/app.jar"]
