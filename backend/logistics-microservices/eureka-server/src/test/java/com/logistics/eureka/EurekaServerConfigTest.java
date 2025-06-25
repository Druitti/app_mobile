package com.logistics.eureka;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = {
    "eureka.client.register-with-eureka=false",
    "eureka.client.fetch-registry=false",
    "spring.cloud.config.enabled=false",
    "eureka.server.enable-self-preservation=false"
})
public class EurekaServerConfigTest {

    @Autowired
    private ApplicationContext applicationContext;

    @Test
    public void contextLoads() {
        assertThat(applicationContext).isNotNull();
    }

    @Test
    public void eurekaServerApplicationExists() {

        boolean hasEurekaApp = applicationContext.containsBean("eurekaServerApplication");
       
        assertThat(applicationContext.getBeanDefinitionCount()).isGreaterThan(0);
    }

    @Test
    public void springProfilesTest() {

        String[] profiles = applicationContext.getEnvironment().getActiveProfiles();
     
        assertThat(applicationContext.getEnvironment()).isNotNull();
    }
}