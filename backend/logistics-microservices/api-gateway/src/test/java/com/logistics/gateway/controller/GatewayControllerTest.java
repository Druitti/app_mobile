package com.logistics.gateway.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.reactive.WebFluxTest;
import org.springframework.test.web.reactive.server.WebTestClient;

@WebFluxTest(GatewayController.class)
public class GatewayControllerTest {

    @Autowired
    private WebTestClient webTestClient;

    @Test
    public void testHealth() {
        webTestClient.get().uri("/api/gateway/health")
                .exchange()
                .expectStatus().isOk();
    }

    @Test
    public void testInfo() {
        webTestClient.get().uri("/api/gateway/info")
                .exchange()
                .expectStatus().isOk();
    }
}
