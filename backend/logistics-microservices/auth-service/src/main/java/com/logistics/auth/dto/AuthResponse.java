package com.logistics.auth.dto;

import com.logistics.auth.model.User;

public class AuthResponse {
    private String token;
    private String refreshToken;
    private User.UserType userType;
    private String email;
    private Long userId;
    
    public AuthResponse(String token, String refreshToken, User user) {
        this.token = token;
        this.refreshToken = refreshToken;
        this.userType = user.getUserType();
        this.email = user.getEmail();
        this.userId = user.getId();
    }
    
    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
    
    public String getRefreshToken() { return refreshToken; }
    public void setRefreshToken(String refreshToken) { this.refreshToken = refreshToken; }
    
    public User.UserType getUserType() { return userType; }
    public void setUserType(User.UserType userType) { this.userType = userType; }
    
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
}