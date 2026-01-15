package com.example.customer;

import com.example.customer.model.AccountStatus;
import com.example.customer.model.Customer;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class CustomerControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void getAllCustomers_returns200() throws Exception {
        mockMvc.perform(get("/customers"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void getCustomerById_validId_returns200() throws Exception {
        mockMvc.perform(get("/customers/123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("John"));
    }

    @Test
    void getCustomerById_invalidId_returns404() throws Exception {
        mockMvc.perform(get("/customers/bad-id"))
                .andExpect(status().isNotFound());
    }

    @Test
    void createCustomer_validInput_returns201() throws Exception {
        Customer customer = new Customer();
        customer.setFirstName("Test");
        customer.setLastName("User");
        customer.setEmail("test@example.com");
        customer.setAccountStatus(AccountStatus.ACTIVE);

        mockMvc.perform(post("/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customer)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").exists())
                .andExpect(jsonPath("$.firstName").value("Test"));
    }

    @Test
    void createCustomer_invalidInput_returns400() throws Exception {
        Customer customer = new Customer();
        customer.setFirstName("");
        customer.setLastName("User");
        customer.setEmail("invalid-email");
        customer.setAccountStatus(AccountStatus.ACTIVE);

        mockMvc.perform(post("/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customer)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void updateCustomer_validId_returns200() throws Exception {
        Customer customer = new Customer();
        customer.setFirstName("Updated");
        customer.setLastName("Customer");
        customer.setEmail("updated@example.com");
        customer.setAccountStatus(AccountStatus.ACTIVE);

        mockMvc.perform(put("/customers/123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customer)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Updated"));
    }

    @Test
    void updateCustomer_invalidId_returns404() throws Exception {
        Customer customer = new Customer();
        customer.setFirstName("Updated");
        customer.setLastName("Customer");
        customer.setEmail("updated@example.com");
        customer.setAccountStatus(AccountStatus.ACTIVE);

        mockMvc.perform(put("/customers/bad-id")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customer)))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteCustomer_validId_returns204() throws Exception {
        mockMvc.perform(delete("/customers/123"))
                .andExpect(status().isNoContent());
    }

    @Test
    void deleteCustomer_invalidId_returns404() throws Exception {
        mockMvc.perform(delete("/customers/bad-id"))
                .andExpect(status().isNotFound());
    }

    @Test
    void healthCheck_returns200() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk());
    }
}
