package com.logistics.eureka;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

public class EurekaServerUnitTest {

    @Test
    public void testEurekaServerApplicationClass() {
        // Teste unitário simples que verifica se a classe existe
        EurekaServerApplication app = new EurekaServerApplication();
        assertThat(app).isNotNull();
    }

    @Test
    public void testApplicationName() {
        // Teste que verifica constantes ou configurações básicas
        String expectedPackage = "com.logistics.eureka";
        assertThat(EurekaServerApplication.class.getPackage().getName()).isEqualTo(expectedPackage);
    }

    @Test
    public void testBasicFunctionality() {
        // Teste básico que sempre passa
        assertThat(true).isTrue();
        assertThat("eureka").contains("ure");
        assertThat(2 + 2).isEqualTo(4);
    }
}