package com.logistics.eureka;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = {
    "eureka.client.register-with-eureka=false",
    "eureka.client.fetch-registry=false",
    "spring.cloud.config.enabled=false",
    "eureka.server.enable-self-preservation=false"
})
class EurekaServerApplicationTests {

    @Test
    void contextLoads() {
        // Teste básico que verifica se o contexto Spring carrega
        // sem iniciar o servidor web (evita conflitos de porta)
    }
}