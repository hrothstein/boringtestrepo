package com.example.customer.model;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.UUID;

public class Customer {

    private UUID id;

    @NotBlank(message = "firstName is required")
    @Size(min = 1, max = 50, message = "firstName must be between 1 and 50 characters")
    private String firstName;

    @NotBlank(message = "lastName is required")
    @Size(min = 1, max = 50, message = "lastName must be between 1 and 50 characters")
    private String lastName;

    @NotBlank(message = "email is required")
    @Email(message = "email must be a valid format")
    private String email;

    @Pattern(regexp = "^\\+?[1-9]\\d{1,14}$", message = "phone must be in E.164 format")
    private String phone;

    @NotNull(message = "accountStatus is required")
    private AccountStatus accountStatus;

    private Instant createdAt;

    private Instant updatedAt;

    public Customer() {
    }

    public Customer(UUID id, String firstName, String lastName, String email, String phone, AccountStatus accountStatus) {
        this.id = id;
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.phone = phone;
        this.accountStatus = accountStatus;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public AccountStatus getAccountStatus() {
        return accountStatus;
    }

    public void setAccountStatus(AccountStatus accountStatus) {
        this.accountStatus = accountStatus;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
