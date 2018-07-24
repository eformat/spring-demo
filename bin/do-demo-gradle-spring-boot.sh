#!/usr/bin/env bash

cat <<'EOF' > src/main/resources/application.yaml
management:
  endpoint:
    restart:
      enabled: true
    health:
      enabled: true
    info:
      enabled: true

helloservice:
  message: "default hello"
EOF

cat <<'EOF' > src/main/resources/bootstrap.yaml
spring:
  application:
    name: helloservice
  cloud:
    kubernetes:
      reload:
        enabled: true
        mode: polling
        period: 5000
      config:
        sources:
          - name: other
          - name: ${spring.application.name}
EOF

cat <<'EOF' > build.gradle
buildscript {
    ext {
        springBootVersion = '2.0.3.RELEASE'
    }
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("org.springframework.boot:spring-boot-gradle-plugin:${springBootVersion}")
    }
}

apply plugin: 'java'
apply plugin: 'eclipse'
apply plugin: 'org.springframework.boot'
apply plugin: 'io.spring.dependency-management'

group = 'com.example'
version = '0.0.1-SNAPSHOT'
sourceCompatibility = 1.8
targetCompatibility = 1.8

repositories {
    mavenCentral()
    maven { url "http://repo.springsource.org/snapshot" }
    maven { url "http://repo.springsource.org/release" }
    maven { url "http://repo.springsource.org/milestone" }
    maven { url "http://mvnrepository.com/artifact" }
}

dependencies {
    compile('org.springframework.boot:spring-boot-starter-actuator')
    compile('org.springframework.boot:spring-boot-starter-web')
    compile('org.springframework.cloud:spring-cloud-starter-kubernetes-config:0.3.0.RC1')
    testCompile('org.springframework.boot:spring-boot-starter-test')
}

defaultTasks 'clean', 'build'
EOF

cat <<'EOF' > src/main/java/com/example/demogradle/DemoGradleApplication.java
package com.example.demogradle;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
public class DemoGradleApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoGradleApplication.class, args);
    }
}
@RestController()
@RequestMapping("/api")
class HelloController {
    private static int counter = 0;
    @Autowired
    private HelloConfig config;

    @Value("#{environment.HELLO_USERNAME}")
    public String username;

    @Value("#{environment.HELLO_PASSWORD}")
    public String password;

    @RequestMapping(value = "/hello/{name}", method = RequestMethod.GET)
    public Map<String, Object> hello(@PathVariable String name) throws Exception {
        HashMap<String, Object> response = new HashMap<>();
        String resp = config.getMessage();
        if (null != username) {
            resp += " your username/password is: " + username + "/" + password;
        }
        response.put("response", resp);
        response.put("your-name", name);
        response.put("count", counter++);
        return response;
    }
}
EOF

cat <<'EOF' > src/main/java/com/example/demogradle/HelloConfig.java
package com.example.demogradle;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "helloservice")
public class HelloConfig {

    private String message;

    public HelloConfig() {
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
EOF

cat <<'EOF' > src/main/resources/application.properties
spring.application.name=helloservice

# Enable auto-reload
spring.cloud.kubernetes.reload.enabled=true

helloservice.message=default hello
EOF

cat <<EOF > configmap.yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: helloservice
data:
  application.yaml: |-
    helloservice:
      message: hello, spring cloud kubernetes !
EOF

cat <<EOF > secret.yaml
kind: Secret
apiVersion: v1
metadata:
  name: helloservice
data:
  HELLO_PASSWORD: cGFzc3dvcmQ=
  HELLO_USERNAME: bWlja2V5bW91c2U=
EOF
