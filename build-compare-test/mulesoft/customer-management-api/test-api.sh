#!/bin/bash

# Test script for Customer Management API
# Based on PRD v5 and OpenAPI specification

BASE_URL="http://localhost:8081"
RESULTS_FILE="test-results-$(date +%Y%m%d-%H%M%S).json"
TEST_LOG="test-execution.log"
MAX_WAIT=120  # Maximum seconds to wait for app to start
WAIT_INTERVAL=2  # Seconds between retry attempts

echo "=========================================" | tee -a "$TEST_LOG"
echo "Customer Management API Test Suite" | tee -a "$TEST_LOG"
echo "Started: $(date)" | tee -a "$TEST_LOG"
echo "=========================================" | tee -a "$TEST_LOG"
echo ""

# Wait for application to be ready
echo "Waiting for application to be ready..." | tee -a "$TEST_LOG"
WAIT_COUNT=0
while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if curl -s -f "$BASE_URL/health" > /dev/null 2>&1; then
        echo "Application is ready!" | tee -a "$TEST_LOG"
        break
    fi
    echo -n "."
    sleep $WAIT_INTERVAL
    WAIT_COUNT=$((WAIT_COUNT + WAIT_INTERVAL))
done
echo ""

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    echo "ERROR: Application did not become ready within $MAX_WAIT seconds" | tee -a "$TEST_LOG"
    echo "Please ensure the Mule application is running on port 8081" | tee -a "$TEST_LOG"
    exit 1
fi

# Initialize results
PASSED=0
FAILED=0
TOTAL=0

# Test result tracking
declare -a TEST_RESULTS

# Helper function to log test results
log_test() {
    local test_name=$1
    local status=$2
    local message=$3
    local response_code=$4
    local response_body=$5
    
    TOTAL=$((TOTAL + 1))
    if [ "$status" == "PASS" ]; then
        PASSED=$((PASSED + 1))
        echo "✓ PASS: $test_name" | tee -a "$TEST_LOG"
    else
        FAILED=$((FAILED + 1))
        echo "✗ FAIL: $test_name - $message" | tee -a "$TEST_LOG"
        if [ -n "$response_body" ] && [ "$response_body" != "" ]; then
            echo "  Response: $response_body" | tee -a "$TEST_LOG"
        fi
    fi
    
    # Escape JSON special characters in response_body
    local escaped_body=$(echo "$response_body" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\r/\\r/g' | head -c 500)
    TEST_RESULTS+=("{\"name\":\"$test_name\",\"status\":\"$status\",\"message\":\"$message\",\"response_code\":\"$response_code\",\"response\":\"$escaped_body\"}")
}

# Test 1: Health Check
echo "Test 1: Health Check Endpoint"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/health")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "200" ] && echo "$body" | grep -q "UP"; then
    log_test "health-check" "PASS" "Health endpoint returns UP" "$http_code" "$body"
else
    log_test "health-check" "FAIL" "Health endpoint failed" "$http_code" "$body"
fi
echo ""

# Test 2: GET all customers (should be empty initially)
echo "Test 2: GET /customers (empty list)"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/customers")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "200" ] && echo "$body" | grep -q "\[\]"; then
    log_test "get-all-customers-empty" "PASS" "Returns empty array" "$http_code" "$body"
else
    log_test "get-all-customers-empty" "FAIL" "Expected empty array" "$http_code" "$body"
fi
echo ""

# Test 3: POST create customer - valid data
echo "Test 3: POST /customers (create valid customer)"
customer_data='{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
  "accountStatus": "ACTIVE"
}'
response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/customers" \
  -H "Content-Type: application/json" \
  -d "$customer_data")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "201" ] && echo "$body" | grep -q "id"; then
    customer_id=$(echo "$body" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    log_test "create-customer-valid" "PASS" "Customer created successfully" "$http_code" "$body"
else
    log_test "create-customer-valid" "FAIL" "Failed to create customer" "$http_code" "$body"
fi
echo ""

# Test 4: POST create customer - missing required field
echo "Test 4: POST /customers (missing firstName)"
invalid_data='{
  "lastName": "Doe",
  "email": "test@example.com"
}'
response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/customers" \
  -H "Content-Type: application/json" \
  -d "$invalid_data")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "400" ] && echo "$body" | grep -qi "firstName"; then
    log_test "create-customer-missing-firstname" "PASS" "Correctly rejected missing firstName" "$http_code" "$body"
else
    log_test "create-customer-missing-firstname" "FAIL" "Should reject missing firstName" "$http_code" "$body"
fi
echo ""

# Test 5: POST create customer - invalid email format
echo "Test 5: POST /customers (invalid email)"
invalid_email='{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "invalid-email"
}'
response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/customers" \
  -H "Content-Type: application/json" \
  -d "$invalid_email")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "400" ] && echo "$body" | grep -qi "email"; then
    log_test "create-customer-invalid-email" "PASS" "Correctly rejected invalid email" "$http_code" "$body"
else
    log_test "create-customer-invalid-email" "FAIL" "Should reject invalid email" "$http_code" "$body"
fi
echo ""

# Test 6: POST create customer - invalid phone format
echo "Test 6: POST /customers (invalid phone format)"
invalid_phone='{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "jane@example.com",
  "phone": "1234567890"
}'
response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/customers" \
  -H "Content-Type: application/json" \
  -d "$invalid_phone")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "400" ] && echo "$body" | grep -qi "phone\|E.164"; then
    log_test "create-customer-invalid-phone" "PASS" "Correctly rejected invalid phone" "$http_code" "$body"
else
    log_test "create-customer-invalid-phone" "FAIL" "Should reject invalid phone format" "$http_code" "$body"
fi
echo ""

# Test 7: POST create customer - invalid accountStatus
echo "Test 7: POST /customers (invalid accountStatus)"
invalid_status='{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "jane2@example.com",
  "accountStatus": "INVALID"
}'
response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/customers" \
  -H "Content-Type: application/json" \
  -d "$invalid_status")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "400" ] && echo "$body" | grep -qi "accountStatus\|ACTIVE\|INACTIVE\|SUSPENDED"; then
    log_test "create-customer-invalid-status" "PASS" "Correctly rejected invalid status" "$http_code" "$body"
else
    log_test "create-customer-invalid-status" "FAIL" "Should reject invalid accountStatus" "$http_code" "$body"
fi
echo ""

# Test 8: POST create customer - duplicate email
echo "Test 8: POST /customers (duplicate email)"
duplicate_email='{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "john.doe@example.com"
}'
response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/customers" \
  -H "Content-Type: application/json" \
  -d "$duplicate_email")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "400" ] && echo "$body" | grep -qi "email\|already\|exists"; then
    log_test "create-customer-duplicate-email" "PASS" "Correctly rejected duplicate email" "$http_code" "$body"
else
    log_test "create-customer-duplicate-email" "FAIL" "Should reject duplicate email" "$http_code" "$body"
fi
echo ""

# Test 9: POST create customer - missing Content-Type
echo "Test 9: POST /customers (missing Content-Type)"
response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/customers" \
  -d "$customer_data")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "400" ] || [ "$http_code" == "415" ]; then
    log_test "create-customer-missing-content-type" "PASS" "Correctly rejected missing Content-Type" "$http_code" "$body"
else
    log_test "create-customer-missing-content-type" "FAIL" "Should reject missing Content-Type" "$http_code" "$body"
fi
echo ""

# Test 10: GET customer by ID - existing customer
echo "Test 10: GET /customers/{id} (existing customer)"
if [ -n "$customer_id" ]; then
    response=$(curl -s -w "\n%{http_code}" "$BASE_URL/customers/$customer_id")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    if [ "$http_code" == "200" ] && echo "$body" | grep -q "john.doe@example.com"; then
        log_test "get-customer-by-id-existing" "PASS" "Retrieved customer successfully" "$http_code" "$body"
    else
        log_test "get-customer-by-id-existing" "FAIL" "Failed to retrieve customer" "$http_code" "$body"
    fi
else
    log_test "get-customer-by-id-existing" "SKIP" "No customer ID available" "N/A" "N/A"
fi
echo ""

# Test 11: GET customer by ID - non-existing customer
echo "Test 11: GET /customers/{id} (non-existing customer)"
fake_id="550e8400-e29b-41d4-a716-446655440000"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/customers/$fake_id")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "404" ] && echo "$body" | grep -qi "not found"; then
    log_test "get-customer-by-id-not-found" "PASS" "Correctly returned 404" "$http_code" "$body"
else
    log_test "get-customer-by-id-not-found" "FAIL" "Should return 404 for non-existing customer" "$http_code" "$body"
fi
echo ""

# Test 12: PUT update customer - valid update
echo "Test 12: PUT /customers/{id} (valid update)"
if [ -n "$customer_id" ]; then
    update_data='{
      "firstName": "John",
      "lastName": "Updated",
      "email": "john.doe@example.com",
      "phone": "+1987654321",
      "accountStatus": "INACTIVE"
    }'
    response=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/customers/$customer_id" \
      -H "Content-Type: application/json" \
      -d "$update_data")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    if [ "$http_code" == "200" ] && echo "$body" | grep -q "Updated"; then
        log_test "update-customer-valid" "PASS" "Customer updated successfully" "$http_code" "$body"
    else
        log_test "update-customer-valid" "FAIL" "Failed to update customer" "$http_code" "$body"
    fi
else
    log_test "update-customer-valid" "SKIP" "No customer ID available" "N/A" "N/A"
fi
echo ""

# Test 13: PUT update customer - non-existing customer
echo "Test 13: PUT /customers/{id} (non-existing customer)"
response=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/customers/$fake_id" \
  -H "Content-Type: application/json" \
  -d "$update_data")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "404" ] && echo "$body" | grep -qi "not found"; then
    log_test "update-customer-not-found" "PASS" "Correctly returned 404" "$http_code" "$body"
else
    log_test "update-customer-not-found" "FAIL" "Should return 404 for non-existing customer" "$http_code" "$body"
fi
echo ""

# Test 14: DELETE customer - existing customer
echo "Test 14: DELETE /customers/{id} (existing customer)"
if [ -n "$customer_id" ]; then
    response=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/customers/$customer_id")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    if [ "$http_code" == "200" ] && echo "$body" | grep -qi "deleted\|success"; then
        log_test "delete-customer-existing" "PASS" "Customer deleted successfully" "$http_code" "$body"
    else
        log_test "delete-customer-existing" "FAIL" "Failed to delete customer" "$http_code" "$body"
    fi
else
    log_test "delete-customer-existing" "SKIP" "No customer ID available" "N/A" "N/A"
fi
echo ""

# Test 15: DELETE customer - non-existing customer
echo "Test 15: DELETE /customers/{id} (non-existing customer)"
response=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/customers/$fake_id")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "404" ] && echo "$body" | grep -qi "not found"; then
    log_test "delete-customer-not-found" "PASS" "Correctly returned 404" "$http_code" "$body"
else
    log_test "delete-customer-not-found" "FAIL" "Should return 404 for non-existing customer" "$http_code" "$body"
fi
echo ""

# Test 16: GET all customers - with data
echo "Test 16: GET /customers (with customers)"
# Create a test customer first
test_customer='{
  "firstName": "Test",
  "lastName": "User",
  "email": "test.user@example.com",
  "accountStatus": "ACTIVE"
}'
curl -s -X POST "$BASE_URL/customers" -H "Content-Type: application/json" -d "$test_customer" > /dev/null

response=$(curl -s -w "\n%{http_code}" "$BASE_URL/customers")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
if [ "$http_code" == "200" ] && echo "$body" | grep -q "test.user@example.com"; then
    log_test "get-all-customers-with-data" "PASS" "Returns customer list" "$http_code" "$body"
else
    log_test "get-all-customers-with-data" "FAIL" "Failed to retrieve customers" "$http_code" "$body"
fi
echo ""

# Summary
echo "=========================================" | tee -a "$TEST_LOG"
echo "Test Summary" | tee -a "$TEST_LOG"
echo "Total Tests: $TOTAL" | tee -a "$TEST_LOG"
echo "Passed: $PASSED" | tee -a "$TEST_LOG"
echo "Failed: $FAILED" | tee -a "$TEST_LOG"
echo "Pass Rate: $(( PASSED * 100 / TOTAL ))%" | tee -a "$TEST_LOG"
echo "Completed: $(date)" | tee -a "$TEST_LOG"
echo "=========================================" | tee -a "$TEST_LOG"

# Generate JSON results
echo "{" > "$RESULTS_FILE"
echo "  \"test_suite\": \"customer-api-prd-test-suite\"," >> "$RESULTS_FILE"
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"," >> "$RESULTS_FILE"
echo "  \"total_tests\": $TOTAL," >> "$RESULTS_FILE"
echo "  \"passed\": $PASSED," >> "$RESULTS_FILE"
echo "  \"failed\": $FAILED," >> "$RESULTS_FILE"
echo "  \"pass_rate\": \"$(( PASSED * 100 / TOTAL ))%\"," >> "$RESULTS_FILE"
echo "  \"tests\": [" >> "$RESULTS_FILE"
for i in "${!TEST_RESULTS[@]}"; do
    echo "    ${TEST_RESULTS[$i]}" >> "$RESULTS_FILE"
    if [ $i -lt $((${#TEST_RESULTS[@]} - 1)) ]; then
        echo "," >> "$RESULTS_FILE"
    fi
done
echo "  ]" >> "$RESULTS_FILE"
echo "}" >> "$RESULTS_FILE"

echo ""
echo "Results saved to: $RESULTS_FILE"
echo "Test log saved to: $TEST_LOG"
