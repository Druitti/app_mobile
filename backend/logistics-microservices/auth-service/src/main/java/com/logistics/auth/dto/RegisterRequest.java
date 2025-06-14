package com.logistics.auth.dto;

import com.logistics.auth.model.User;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class RegisterRequest {
    @Email
    @NotBlank
    private String email;
    
    @NotBlank
    private String password;
    
    @NotNull
    private User.UserType userType;
    
    private String firstName;
    private String lastName;
    private String phone;
    
    public RegisterRequest() {}
    
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    
    public User.UserType getUserType() { return userType; }
    public void setUserType(User.UserType userType) { this.userType = userType; }
    
    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }
    
    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }
    
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
}