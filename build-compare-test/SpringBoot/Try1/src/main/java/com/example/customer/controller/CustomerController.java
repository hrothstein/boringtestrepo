package com.example.customer.controller;

import com.example.customer.model.AccountStatus;
import com.example.customer.model.Customer;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/customers")
public class CustomerController {

    private static final String VALID_ID = "123";

    private final List<Customer> mockCustomers = Arrays.asList(
            new Customer(
                    UUID.fromString("00000000-0000-0000-0000-000000000123"),
                    "John",
                    "Doe",
                    "john.doe@example.com",
                    "+12025551234",
                    AccountStatus.ACTIVE
            ),
            new Customer(
                    UUID.fromString("00000000-0000-0000-0000-000000000456"),
                    "Jane",
                    "Smith",
                    "jane.smith@example.com",
                    "+12025555678",
                    AccountStatus.ACTIVE
            )
    );

    @GetMapping
    public ResponseEntity<List<Customer>> getAllCustomers() {
        return ResponseEntity.ok(mockCustomers);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Customer> getCustomerById(@PathVariable String id) {
        if (VALID_ID.equals(id)) {
            return ResponseEntity.ok(mockCustomers.get(0));
        }
        return ResponseEntity.notFound().build();
    }

    @PostMapping
    public ResponseEntity<Customer> createCustomer(@Valid @RequestBody Customer customer) {
        customer.setId(UUID.randomUUID());
        customer.setCreatedAt(Instant.now());
        customer.setUpdatedAt(Instant.now());
        return ResponseEntity.status(HttpStatus.CREATED).body(customer);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Customer> updateCustomer(@PathVariable String id, @Valid @RequestBody Customer customer) {
        if (VALID_ID.equals(id)) {
            customer.setId(mockCustomers.get(0).getId());
            customer.setCreatedAt(mockCustomers.get(0).getCreatedAt());
            customer.setUpdatedAt(Instant.now());
            return ResponseEntity.ok(customer);
        }
        return ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCustomer(@PathVariable String id) {
        if (VALID_ID.equals(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
