package com.logistics.orders.client;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.logistics.orders.model.User;
import java.util.List;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;

@FeignClient(name = "user-service", url = "http://localhost:8082")
public interface UserServiceClient {
    
    @GetMapping("/api/auth/user/{id}")
    User getUserById(@PathVariable("id") Long id);
   
}