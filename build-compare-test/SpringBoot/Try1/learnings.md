# Learnings - Spring Boot Customer Management API

## Implementation Notes

### What Worked Well
1. **Spring Boot 3.x with Jakarta Validation** - The `jakarta.validation` annotations work seamlessly for input validation
2. **ResponseEntity for Status Codes** - Using `ResponseEntity.status(HttpStatus.CREATED)` and similar methods made setting correct HTTP status codes straightforward
3. **@ControllerAdvice for Global Error Handling** - Clean separation of error handling logic from business logic
4. **Spring Actuator** - Health endpoint comes out of the box with minimal configuration

### Key Implementation Decisions
1. Used mock data with hardcoded customers rather than actual persistence
2. Used `id="123"` as the "valid" ID for testing purposes
3. Kept error responses consistent with `{"error": "...", "message": "..."}` format
4. No stack traces exposed in error responses

### Errors Encountered
None - implementation completed without errors on first attempt.

### Status Code Implementation
- `GET /customers` → 200 OK (via `ResponseEntity.ok()`)
- `GET /customers/{id}` → 200 OK or 404 Not Found (via `ResponseEntity.notFound().build()`)
- `POST /customers` → 201 Created (via `ResponseEntity.status(HttpStatus.CREATED)`)
- `PUT /customers/{id}` → 200 OK or 404 Not Found
- `DELETE /customers/{id}` → 204 No Content (via `ResponseEntity.noContent().build()`) or 404 Not Found

### Test Results
- 10/10 unit tests passed
- All endpoint status codes verified correct via curl
