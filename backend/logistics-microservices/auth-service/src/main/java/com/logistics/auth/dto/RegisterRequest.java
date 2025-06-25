package com.logistics.auth.dto;

import com.logistics.auth.model.User;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class RegisterRequest {
    @Email(message = "E-mail inválido")
    @NotBlank(message = "O e-mail é obrigatório")
    private String email;
    
    @NotBlank(message = "A senha é obrigatória")
    private String password;
    
    @NotNull(message = "O tipo de usuário é obrigatório")
    private User.UserType userType;
    
    @NotBlank(message = "O nome é obrigatório")
    private String firstName;
    
    @NotBlank(message = "O sobrenome é obrigatório")
    private String lastName;
    
    @NotBlank(message = "O número de telefone é obrigatório")
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