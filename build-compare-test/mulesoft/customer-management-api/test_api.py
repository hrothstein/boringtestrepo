#!/usr/bin/env python3
"""
Customer Management API Test Suite
Tests all endpoints according to PRD v5 requirements
"""

import requests
import json
import time
import sys
from datetime import datetime

BASE_URL = "http://localhost:8081"
MAX_WAIT = 120
WAIT_INTERVAL = 2

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def wait_for_app():
    """Wait for application to be ready"""
    print(f"{Colors.BLUE}Waiting for application to be ready...{Colors.END}")
    start_time = time.time()
    while time.time() - start_time < MAX_WAIT:
        try:
            response = requests.get(f"{BASE_URL}/health", timeout=2)
            if response.status_code == 200:
                print(f"{Colors.GREEN}Application is ready!{Colors.END}\n")
                return True
        except:
            pass
        print(".", end="", flush=True)
        time.sleep(WAIT_INTERVAL)
    print(f"\n{Colors.RED}ERROR: Application did not become ready within {MAX_WAIT} seconds{Colors.END}")
    return False

def run_test(name, method, url, headers=None, data=None, expected_status=200, expected_in_response=None):
    """Run a single test case"""
    try:
        if method == "GET":
            response = requests.get(url, headers=headers, timeout=5)
        elif method == "POST":
            response = requests.post(url, headers=headers, json=data, timeout=5)
        elif method == "PUT":
            response = requests.put(url, headers=headers, json=data, timeout=5)
        elif method == "DELETE":
            response = requests.delete(url, headers=headers, timeout=5)
        else:
            return False, f"Unknown method: {method}", None, None
        
        status_match = response.status_code == expected_status
        content_match = True
        if expected_in_response:
            response_text = response.text.lower()
            if isinstance(expected_in_response, list):
                content_match = any(term.lower() in response_text for term in expected_in_response)
            else:
                content_match = expected_in_response.lower() in response_text
        
        if status_match and content_match:
            return True, "PASS", response.status_code, response.text[:200]
        else:
            msg = f"Expected status {expected_status}, got {response.status_code}"
            if expected_in_response and not content_match:
                msg += f" | Expected content not found"
            return False, msg, response.status_code, response.text[:200]
    except requests.exceptions.ConnectionError:
        return False, "Connection refused - app not running", None, None
    except Exception as e:
        return False, str(e), None, None

def main():
    print("=" * 60)
    print("Customer Management API Test Suite")
    print(f"Started: {datetime.now()}")
    print("=" * 60)
    print()
    
    if not wait_for_app():
        sys.exit(1)
    
    results = []
    passed = 0
    failed = 0
    
    # Test 1: Health Check
    print(f"{Colors.BLUE}Test 1: Health Check{Colors.END}")
    success, msg, code, body = run_test("health-check", "GET", f"{BASE_URL}/health", 
                                        expected_status=200, expected_in_response="UP")
    if success:
        print(f"{Colors.GREEN}✓ PASS{Colors.END}")
        passed += 1
    else:
        print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
        failed += 1
    results.append({"name": "health-check", "status": "PASS" if success else "FAIL", "message": msg})
    print()
    
    # Test 2: GET all customers (empty)
    print(f"{Colors.BLUE}Test 2: GET /customers (empty list){Colors.END}")
    success, msg, code, body = run_test("get-all-empty", "GET", f"{BASE_URL}/customers",
                                        expected_status=200, expected_in_response="[]")
    if success:
        print(f"{Colors.GREEN}✓ PASS{Colors.END}")
        passed += 1
    else:
        print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
        failed += 1
    results.append({"name": "get-all-empty", "status": "PASS" if success else "FAIL", "message": msg})
    print()
    
    # Test 3: POST create customer - valid
    print(f"{Colors.BLUE}Test 3: POST /customers (create valid customer){Colors.END}")
    customer_data = {
        "firstName": "John",
        "lastName": "Doe",
        "email": "john.doe@example.com",
        "phone": "+1234567890",
        "accountStatus": "ACTIVE"
    }
    success, msg, code, body = run_test("create-valid", "POST", f"{BASE_URL}/customers",
                                       headers={"Content-Type": "application/json"},
                                       data=customer_data, expected_status=201,
                                       expected_in_response="id")
    customer_id = None
    if success:
        try:
            customer_id = json.loads(body).get("id")
            print(f"{Colors.GREEN}✓ PASS (ID: {customer_id}){Colors.END}")
            passed += 1
        except:
            print(f"{Colors.YELLOW}⚠ PASS (but couldn't parse ID){Colors.END}")
            passed += 1
    else:
        print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
        failed += 1
    results.append({"name": "create-valid", "status": "PASS" if success else "FAIL", "message": msg})
    print()
    
    # Test 4: POST create customer - missing firstName
    print(f"{Colors.BLUE}Test 4: POST /customers (missing firstName){Colors.END}")
    invalid_data = {"lastName": "Doe", "email": "test@example.com"}
    success, msg, code, body = run_test("create-missing-firstname", "POST", f"{BASE_URL}/customers",
                                        headers={"Content-Type": "application/json"},
                                        data=invalid_data, expected_status=400,
                                        expected_in_response=["firstname", "required"])
    if success:
        print(f"{Colors.GREEN}✓ PASS{Colors.END}")
        passed += 1
    else:
        print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
        failed += 1
    results.append({"name": "create-missing-firstname", "status": "PASS" if success else "FAIL", "message": msg})
    print()
    
    # Test 5: POST create customer - invalid email
    print(f"{Colors.BLUE}Test 5: POST /customers (invalid email){Colors.END}")
    invalid_email = {"firstName": "Jane", "lastName": "Smith", "email": "invalid-email"}
    success, msg, code, body = run_test("create-invalid-email", "POST", f"{BASE_URL}/customers",
                                        headers={"Content-Type": "application/json"},
                                        data=invalid_email, expected_status=400,
                                        expected_in_response=["email", "valid"])
    if success:
        print(f"{Colors.GREEN}✓ PASS{Colors.END}")
        passed += 1
    else:
        print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
        failed += 1
    results.append({"name": "create-invalid-email", "status": "PASS" if success else "FAIL", "message": msg})
    print()
    
    # Test 6: POST create customer - invalid phone
    print(f"{Colors.BLUE}Test 6: POST /customers (invalid phone format){Colors.END}")
    invalid_phone = {"firstName": "Jane", "lastName": "Smith", "email": "jane@example.com", "phone": "1234567890"}
    success, msg, code, body = run_test("create-invalid-phone", "POST", f"{BASE_URL}/customers",
                                        headers={"Content-Type": "application/json"},
                                        data=invalid_phone, expected_status=400,
                                        expected_in_response=["phone", "e.164"])
    if success:
        print(f"{Colors.GREEN}✓ PASS{Colors.END}")
        passed += 1
    else:
        print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
        failed += 1
    results.append({"name": "create-invalid-phone", "status": "PASS" if success else "FAIL", "message": msg})
    print()
    
    # Test 7: POST create customer - duplicate email
    if customer_id:
        print(f"{Colors.BLUE}Test 7: POST /customers (duplicate email){Colors.END}")
        duplicate = {"firstName": "Jane", "lastName": "Smith", "email": "john.doe@example.com"}
        success, msg, code, body = run_test("create-duplicate-email", "POST", f"{BASE_URL}/customers",
                                            headers={"Content-Type": "application/json"},
                                            data=duplicate, expected_status=400,
                                            expected_in_response=["email", "already", "exists"])
        if success:
            print(f"{Colors.GREEN}✓ PASS{Colors.END}")
            passed += 1
        else:
            print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
            failed += 1
        results.append({"name": "create-duplicate-email", "status": "PASS" if success else "FAIL", "message": msg})
        print()
    
    # Test 8: GET customer by ID
    if customer_id:
        print(f"{Colors.BLUE}Test 8: GET /customers/{{id}} (existing customer){Colors.END}")
        success, msg, code, body = run_test("get-by-id", "GET", f"{BASE_URL}/customers/{customer_id}",
                                            expected_status=200, expected_in_response="john.doe@example.com")
        if success:
            print(f"{Colors.GREEN}✓ PASS{Colors.END}")
            passed += 1
        else:
            print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
            failed += 1
        results.append({"name": "get-by-id", "status": "PASS" if success else "FAIL", "message": msg})
        print()
    
    # Test 9: GET customer by ID - not found
    print(f"{Colors.BLUE}Test 9: GET /customers/{{id}} (not found){Colors.END}")
    fake_id = "550e8400-e29b-41d4-a716-446655440000"
    success, msg, code, body = run_test("get-by-id-not-found", "GET", f"{BASE_URL}/customers/{fake_id}",
                                        expected_status=404, expected_in_response=["not found", "404"])
    if success:
        print(f"{Colors.GREEN}✓ PASS{Colors.END}")
        passed += 1
    else:
        print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
        failed += 1
    results.append({"name": "get-by-id-not-found", "status": "PASS" if success else "FAIL", "message": msg})
    print()
    
    # Test 10: PUT update customer
    if customer_id:
        print(f"{Colors.BLUE}Test 10: PUT /customers/{{id}} (update customer){Colors.END}")
        update_data = {"firstName": "John", "lastName": "Updated", "email": "john.doe@example.com", "accountStatus": "INACTIVE"}
        success, msg, code, body = run_test("update-customer", "PUT", f"{BASE_URL}/customers/{customer_id}",
                                            headers={"Content-Type": "application/json"},
                                            data=update_data, expected_status=200,
                                            expected_in_response="Updated")
        if success:
            print(f"{Colors.GREEN}✓ PASS{Colors.END}")
            passed += 1
        else:
            print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
            failed += 1
        results.append({"name": "update-customer", "status": "PASS" if success else "FAIL", "message": msg})
        print()
    
    # Test 11: DELETE customer
    if customer_id:
        print(f"{Colors.BLUE}Test 11: DELETE /customers/{{id}} (delete customer){Colors.END}")
        success, msg, code, body = run_test("delete-customer", "DELETE", f"{BASE_URL}/customers/{customer_id}",
                                            expected_status=200, expected_in_response=["deleted", "success"])
        if success:
            print(f"{Colors.GREEN}✓ PASS{Colors.END}")
            passed += 1
        else:
            print(f"{Colors.RED}✗ FAIL: {msg}{Colors.END}")
            failed += 1
        results.append({"name": "delete-customer", "status": "PASS" if success else "FAIL", "message": msg})
        print()
    
    # Summary
    total = passed + failed
    print("=" * 60)
    print("Test Summary")
    print("=" * 60)
    print(f"Total Tests: {total}")
    print(f"{Colors.GREEN}Passed: {passed}{Colors.END}")
    print(f"{Colors.RED}Failed: {failed}{Colors.END}")
    if total > 0:
        pass_rate = (passed * 100) // total
        print(f"Pass Rate: {pass_rate}%")
    print(f"Completed: {datetime.now()}")
    print("=" * 60)
    
    # Save results
    results_file = f"test-results-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
    with open(results_file, 'w') as f:
        json.dump({
            "test_suite": "customer-api-prd-test-suite",
            "timestamp": datetime.now().isoformat(),
            "total_tests": total,
            "passed": passed,
            "failed": failed,
            "pass_rate": f"{(passed * 100) // total}%" if total > 0 else "0%",
            "tests": results
        }, f, indent=2)
    
    print(f"\nResults saved to: {results_file}")
    
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
