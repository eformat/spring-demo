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

cat <<'EOF' > pom.xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>demo</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>demo</name>
    <description>Demo project for Spring Boot</description>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.0.3.RELEASE</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
        <java.version>1.8</java.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <spring-boot.version>2.0.3.RELEASE</spring-boot.version>
        <spring-cloud-kubernetes.version>0.3.0.RC1</spring-cloud-kubernetes.version>
        <fabric8.maven.plugin.version>3.5.40</fabric8.maven.plugin.version>
        <maven-compiler-plugin.version>3.7.0</maven-compiler-plugin.version>
        <maven-surefire-plugin.version>2.22.0</maven-surefire-plugin.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-configuration-processor</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-kubernetes-config</artifactId>
            <version>${spring-cloud-kubernetes.version}</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>${maven-compiler-plugin.version}</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>${maven-surefire-plugin.version}</version>
                <inherited>true</inherited>
                <configuration>
                    <excludes>
                        <exclude>**/*KT.java</exclude>
                    </excludes>
                </configuration>
            </plugin>

            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${spring-boot.version}</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <plugin>
                <groupId>io.fabric8</groupId>
                <artifactId>fabric8-maven-plugin</artifactId>
                <version>${fabric8.maven.plugin.version}</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>resource</goal>
                            <goal>build</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <resources>
                        <labels>
                            <all>
                                <property>
                                    <name>project</name>
                                    <value>${project.artifactId}</value>
                                </property>
                            </all>
                        </labels>
                    </resources>
                    <generator>
                        <config>
                            <spring-boot>
                                <fromMode>istag</fromMode>
                                <from>openshift/redhat-openjdk18-openshift:1.3</from>
                            </spring-boot>
                        </config>
                    </generator>
                </configuration>
            </plugin>
        </plugins>
    </build>

</project>
EOF

cat <<'EOF' > src/main/java/com/example/demomaven/DemoMavenApplication.java
package com.example.demomaven;

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
public class DemoMavenApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoMavenApplication.class, args);
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


cat <<'EOF' > src/main/java/com/example/demomaven/HelloConfig.java
package com.example.demomaven;

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
