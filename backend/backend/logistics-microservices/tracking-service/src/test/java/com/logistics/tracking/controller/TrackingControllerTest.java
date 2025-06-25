package com.logistics.tracking.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistics.tracking.dto.LocationUpdateRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class TrackingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testUpdateLocationBadRequest() throws Exception {
        LocationUpdateRequest request = new LocationUpdateRequest();
        mockMvc.perform(post("/api/tracking/location")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testGetOrderTrackingNotFound() throws Exception {
        mockMvc.perform(get("/api/tracking/order/999999"))
                .andExpect(status().isNotFound());
    }

    @Test
    public void testGetLocationHistory() throws Exception {
        mockMvc.perform(get("/api/tracking/order/1/history"))
                .andExpect(status().isOk());
    }

    @Test
    public void testGetDriverLocationHistory() throws Exception {
        mockMvc.perform(get("/api/tracking/driver/1/history"))
                .andExpect(status().isOk());
    }

    @Test
    public void testGetCurrentLocationNotFound() throws Exception {
        mockMvc.perform(get("/api/tracking/order/999999/current"))
                .andExpect(status().isNotFound());
    }

    @Test
    public void testGetCurrentDriverLocationNotFound() throws Exception {
        mockMvc.perform(get("/api/tracking/driver/999999/current"))
                .andExpect(status().isNotFound());
    }

    @Test
    public void testGetNearbyDeliveries() throws Exception {
        mockMvc.perform(get("/api/tracking/nearby")
                .param("latitude", "0")
                .param("longitude", "0"))
                .andExpect(status().isOk());
    }

    @Test
    public void testCreateTrackingBadRequest() throws Exception {
        mockMvc.perform(post("/api/tracking/create"))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testMarkAsDeliveredNotFound() throws Exception {
        mockMvc.perform(put("/api/tracking/order/999999/delivered"))
                .andExpect(status().isNotFound());
    }
}
