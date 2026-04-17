FROM maven:3.9-eclipse-temurin-11

WORKDIR /app

# Copy project files
COPY pom.xml .
COPY GaiaCoreClient.java .
COPY Example.java .
COPY PipelineExample.java .

# Download dependencies and compile all classes
RUN mvn dependency:resolve && mvn clean compile

CMD ["mvn", "exec:java", "-Dexec.mainClass=Example"]
