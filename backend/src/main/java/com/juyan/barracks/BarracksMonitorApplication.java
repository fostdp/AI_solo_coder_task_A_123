package com.juyan.barracks;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class BarracksMonitorApplication {

    public static void main(String[] args) {
        SpringApplication.run(BarracksMonitorApplication.class, args);
    }
}
