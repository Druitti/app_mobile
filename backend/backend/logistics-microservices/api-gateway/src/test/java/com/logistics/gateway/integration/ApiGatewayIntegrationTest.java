package com.logistics.gateway.integration;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class ApiGatewayIntegrationTest {

    @LocalServerPort
    private int port;

    @Test
    public void healthEndpointShouldReturnOk() {
        RestTemplate restTemplate = new RestTemplate();
        String url = "http://localhost:" + port + "/api/gateway/health";
        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    public void infoEndpointShouldReturnOk() {
        RestTemplate restTemplate = new RestTemplate();
        String url = "http://localhost:" + port + "/api/gateway/info";
        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
    }

    // Exemplo de teste de roteamento (ajuste a rota conforme sua config):
    // @Test
    // public void routeToSomeServiceShouldReturnExpected() {
    //     RestTemplate restTemplate = new RestTemplate();
    //     String url = "http://localhost:" + port + "/alguma-rota-do-gateway";
    //     ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
    //     assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
    // }
}
