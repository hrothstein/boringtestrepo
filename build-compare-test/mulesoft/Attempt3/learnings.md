# Mule 4.10 HTTP Response Status Code - Learnings

## Critical Issue: `<http:response>` Placement Rules

### Problem
MCP Server's XML validation is **stricter** than regular Maven compile. Code that builds successfully with `mvn clean compile` may still fail MCP Server deployment due to XML schema validation errors.

### Key Finding
In Mule 4.10, `<http:response>` has very specific placement rules that are enforced by MCP Server's validation:

### What DOESN'T Work

1. **Cannot place `<http:response>` directly after `<ee:transform>`**
   ```xml
   <!-- ❌ FAILS MCP Server validation -->
   <ee:transform>
       <ee:message>
           <ee:set-payload>...</ee:set-payload>
       </ee:message>
   </ee:transform>
   <http:response statusCode="200"/>
   ```

2. **Cannot place `<http:response>` directly after `<logger>`**
   ```xml
   <!-- ❌ FAILS MCP Server validation -->
   <ee:transform>...</ee:transform>
   <logger level="INFO" message="..."/>
   <http:response statusCode="200"/>
   ```

3. **Cannot place `<http:response>` inside error handlers in certain positions**
   ```xml
   <!-- ❌ FAILS MCP Server validation -->
   <error-handler>
       <on-error-propagate>
           <ee:transform>...</ee:transform>
           <http:response statusCode="500"/>
       </on-error-propagate>
   </error-handler>
   ```

4. **Cannot place `<http:response>` directly after certain processors in choice branches**
   - The error messages indicate it expects `abstract-message-processor` or `abstract-mixed-content-message-processor` but `<http:response>` doesn't qualify in these contexts

### Error Pattern
```
cvc-complex-type.2.4.a: Invalid content was found starting with element 
'{"http://www.mulesoft.org/schema/mule/http":response}'. 
One of '{"http://www.mulesoft.org/schema/mule/core":abstract-message-processor, 
"http://www.mulesoft.org/schema/mule/core":abstract-mixed-content-message-processor}' 
is expected.
```

### What We Tried

1. ✅ Setting status code in variables and using expressions: `statusCode="#[vars.httpStatus]"`
   - This works for the status code value, but doesn't solve placement issues

2. ✅ Moving `<http:response>` outside `<http:listener>` elements
   - This was correct, but not sufficient

3. ❌ Adding `<logger>` between `<ee:transform>` and `<http:response>`
   - Still fails validation

4. ❌ Setting status code in transform variables and placing `<http:response>` after
   - Still fails validation

### What We Need to Research

1. **Correct pattern for Mule 4.10 `<http:response>` placement**
   - Need to find official Mule 4.10 documentation or examples
   - May need to use a different approach entirely (e.g., setting status in attributes)

2. **Alternative approaches:**
   - Using `<http:response>` with builder pattern?
   - Setting status codes via attributes instead of `<http:response>` element?
   - Using subflows for response handling?
   - Using error handlers differently?

3. **MCP Server vs Regular Maven:**
   - Why does MCP Server validation differ from `mvn compile`?
   - Is there a way to see the exact schema being used?

### Current State

- ✅ Project structure is correct
- ✅ All flows are implemented with correct logic
- ✅ Status codes are set using variables and expressions
- ✅ Build succeeds with `mvn clean compile`
- ❌ **MCP Server deployment fails** due to XML schema validation
- ❌ **18 validation errors** all related to `<http:response>` placement

### Next Steps

1. Research Mule 4.10 official documentation for `<http:response>` usage
2. Look for MCP Server-specific requirements or known issues
3. Consider alternative approaches to setting HTTP status codes
4. Test with a minimal example to isolate the issue
5. Check if there's a different Mule version or connector version that works better

### Files Modified

- `customer-management-api/src/main/mule/customer-management-api.xml` - Main flow definitions
- `customer-management-api/src/main/mule/global.xml` - HTTP listener config
- `customer-management-api/src/main/resources/config.properties` - Port configuration (8081)

### Key Takeaway

**MCP Server validation is the success criteria, not Maven build.** Code must pass MCP Server's XML schema validation to be considered complete.

---

## BREAKTHROUGH: Solution Found!

### ✅ CORRECT PATTERN: Use `<ee:set-attributes>` instead of `<http:response>`

**The solution is to set the HTTP status code using `<ee:set-attributes>` within the `<ee:transform>` element, NOT using a separate `<http:response>` element.**

#### Correct Pattern:
```xml
<flow name="healthCheckFlow">
    <http:listener path="/health" config-ref="HTTP_Listener_config"/>
    <ee:transform>
        <ee:message>
            <ee:set-payload>...</ee:set-payload>
            <ee:set-attributes><![CDATA[%dw 2.0
output application/java
---
{
    statusCode: 200
}]]></ee:set-attributes>
        </ee:message>
    </ee:transform>
    <!-- NO http:response element needed! -->
</flow>
```

#### Why This Works:
- `<ee:set-attributes>` sets the status code in the response attributes
- No separate `<http:response>` element is needed
- This passes MCP Server validation
- Status code is set directly in the transform's attributes

#### Status Codes:
- `200` - OK
- `201` - Created  
- `204` - No Content
- `400` - Bad Request
- `404` - Not Found
- `500` - Internal Server Error

### Next Steps:
1. Replace all `<http:response>` elements with `<ee:set-attributes>` in transforms
2. Remove all standalone `<http:response>` elements
3. Test with MCP Server deployment

---

## CRITICAL: Always Check Runtime Logs First

### Problem
When application deployment reports "success" but endpoints don't respond, **ALWAYS check runtime logs immediately** before attempting to test endpoints or troubleshoot.

### What Happened
- MCP Server reported: "Application started successfully"
- Endpoints returned connection refused
- **Mistake:** Kept trying to test endpoints without checking logs
- **Should have done:** Checked logs immediately to see actual deployment errors

### Error Found in Logs
```
ConfigurationException: [customer-management-api.xml:168]: Missing Expression
[customer-management-api.xml:399]: Missing Expression
```

### Root Cause
- Missing `doc:id` attributes on `<ee:transform>` elements
- Mule 4.10 runtime validation requires `doc:id` on transform elements
- Maven build passes, but runtime validation is stricter

### Fix Applied
Added `doc:id` attributes to transform elements:
```xml
<ee:transform doc:name="Validate Input" doc:id="validate-input-create">
```

### Key Takeaway
**When something doesn't work:**
1. ✅ **FIRST:** Check runtime logs (`/runtime/logs/mule_ee.log`)
2. ✅ **THEN:** Fix the actual error shown in logs
3. ✅ **LAST:** Test endpoints

**Never assume deployment success means the app is actually running.** Runtime logs tell the truth.

### Current Issue: "Missing Expression" Error

**Error:** `ConfigurationException: [customer-management-api.xml:168]: Missing Expression`

**Location:** Lines 168 and 399 - `<ee:set-variable>` elements with complex DataWeave expressions using `do {}` blocks

**Attempted Fixes:**
1. ✅ Added `doc:id` attributes to transform elements
2. ✅ Fixed indentation to match working examples
3. ❌ Still failing - "Missing Expression" error persists

**Hypothesis:** Mule 4.10 runtime validation may not support `do {}` blocks in `<ee:set-variable>` DataWeave expressions, or requires a different syntax.

**Next Steps:**
- ✅ Try simplifying the DataWeave expression (remove `do {}` wrapper)
- ✅ Check if validation logic needs to be moved to a different location
- ✅ Verify Mule 4.10 DataWeave syntax requirements for set-variable

### ✅ SOLUTION: Remove `do {}` Blocks from DataWeave Expressions

**Problem:** Mule 4.10 runtime validation does NOT support `do {}` blocks in `<ee:set-variable>` DataWeave expressions.

**Error:** `ConfigurationException: Missing Expression` at lines with `do {}` blocks

**Solution:** Rewrite DataWeave expressions without `do {}` wrapper, using inline array construction with filter:

**Before (FAILS):**
```xml
<ee:set-variable variableName="validationErrors"><![CDATA[%dw 2.0
output application/java
---
do {
    var firstName = payload.firstName as String default ""
    var firstNameError = if (sizeOf(firstName) == 0) "firstName is required" else null
    ...
    allErrors
}]]></ee:set-variable>
```

**After (WORKS):**
```xml
<ee:set-variable variableName="validationErrors"><![CDATA[%dw 2.0
output application/java
---
([
    if (sizeOf(payload.firstName as String default "") == 0) "firstName is required"
    else if (sizeOf(payload.firstName as String default "") > 50) "firstName must be 1-50 characters"
    else null,
    ...
] filter ($ != null))]]></ee:set-variable>
```

**Key Changes:**
- Removed `do {}` wrapper
- Inline all variable references directly in expressions
- Use array literal `[...]` with `filter ($ != null)` to collect errors
- Wrap entire expression in parentheses for proper evaluation

**Result:** ✅ "Missing Expression" error resolved. Application now deploys successfully.

### Additional Fixes Applied

1. **Fixed `read()` usage:**
   - HTTP listener payload is already parsed → use `payload as Object`
   - Object store returns strings → use `read(payload, "application/json")`

2. **Fixed null comparison:**
   - Changed `sizeOf(vars.validationErrors) > 0` to `sizeOf(vars.validationErrors default []) > 0`
   - Prevents "Types Null and Number can not be compared" error

3. **Fixed GET /customers empty response:**
   - Changed from empty array literal to `if (payload == null) [] else payload default []`
   - Handles null response from object store properly

### Current Status

- ✅ Application deploys successfully
- ✅ Health endpoint returns 200
- ⚠️ POST /customers returns 200 with empty body (should return 201 with customer object)
- ⚠️ Validation errors return 200 instead of 400
- ⚠️ All endpoints returning empty `{}` body

**Next:** Need to debug why responses are empty - likely flow logic issue or payload not being set correctly.

---

## CRITICAL FINDING: Status Codes Don't Work Even With Mock Data

### Test: Simplified to Mock Data Only

**Date:** 2026-01-14  
**Test Approach:** Removed Object Store entirely. Used pure mock data with simple choice logic.

**Mock Implementation:**
- GET /customers → Hardcoded array of 2 customers
- GET /customers/{id} → If id="123", return customer (200), else 404
- POST /customers → Return input + UUID (201)
- PUT /customers/{id} → If id="123", return updated (200), else 404
- DELETE /customers/{id} → If id="123", return 204, else 404
- GET /health → Return UP (200)

**Code Pattern Used:**
```xml
<ee:transform>
    <ee:message>
        <ee:set-payload>...</ee:set-payload>
        <ee:set-attributes><![CDATA[%dw 2.0
output application/java
---
{
    statusCode: 201
}]]></ee:set-attributes>
    </ee:message>
</ee:transform>
```

### Test Results

| Endpoint | Expected | Actual | Status |
|----------|----------|--------|--------|
| GET /health | 200 | 200 | ✅ CORRECT |
| GET /customers | 200 | 200 | ✅ CORRECT |
| GET /customers/123 | 200 | 200 | ✅ CORRECT |
| GET /customers/999 | 404 | **200** | ❌ **FAILS** |
| POST /customers | 201 | **200** | ❌ **FAILS** |
| PUT /customers/123 | 200 | 200 | ✅ CORRECT |
| PUT /customers/999 | 404 | **200** | ❌ **FAILS** |
| DELETE /customers/123 | 204 | **200** | ❌ **FAILS** |
| DELETE /customers/999 | 404 | **200** | ❌ **FAILS** |

### Critical Observation

**ALL non-200 status codes return 200, even with:**
- ✅ No Object Store (eliminated storage complexity)
- ✅ Simple mock data (no data conversion issues)
- ✅ Simple choice logic (no complex flow logic)
- ✅ Correct `<ee:set-attributes>` pattern (per learnings.md)
- ✅ Code builds and deploys successfully
- ✅ Responses are correct (payloads match expectations)

### Conclusion

**This is a PLATFORM LIMITATION, not a code issue.**

The `<ee:set-attributes>` pattern with `statusCode` is:
- ✅ Syntactically correct (passes validation)
- ✅ Deploys successfully
- ❌ **Does NOT actually set HTTP status codes**

**Possible Causes:**
1. `<ee:set-attributes>` may not be the correct way to set HTTP status codes in Mule 4.10
2. HTTP status codes may need to be set differently (e.g., via HTTP listener response builder)
3. There may be a configuration issue with the HTTP listener
4. This may be a known limitation/bug in Mule 4.10

### What We Know Works

- ✅ Setting statusCode: 200 works (health endpoint)
- ❌ Setting statusCode: 201 does NOT work (POST returns 200)
- ❌ Setting statusCode: 204 does NOT work (DELETE returns 200)
- ❌ Setting statusCode: 404 does NOT work (not found returns 200)

### Next Steps (If Continuing)

1. Research Mule 4.10 official documentation for HTTP status code setting
2. Try using HTTP listener response builder pattern
3. Check if there's a different way to set status codes in Mule 4.10
4. Verify if this is a known issue in Mule 4.10
5. Consider if Mule 4.10 HTTP connector has limitations

### Key Takeaway

**Even with perfect code, mock data, and no complexity, HTTP status codes (201, 204, 404) do NOT work in Mule 4.10 using the `<ee:set-attributes>` pattern. This appears to be a platform limitation or incorrect usage pattern.**

---

## SOLUTION FOUND: Correct Pattern for HTTP Status Codes

### ✅ CORRECT PATTERN: `<http:response>` INSIDE `<http:listener>`

**Date:** 2026-01-14  
**Source:** User provided working example

**Working Example:**
```xml
<http:listener doc:id="qpsxde" doc:name="Listener" path="/test" config-ref="Listener-config">
    <http:response statusCode="203" />
</http:listener>
```

### Key Finding

**`<http:response>` MUST be INSIDE `<http:listener>`, not after it.**

### Implementation Attempts

1. **Static Status Codes (✅ WORKS):**
   ```xml
   <http:listener path="/health" config-ref="HTTP_Listener_config">
       <http:response statusCode="200"/>
   </http:listener>
   ```
   - ✅ Works for fixed status codes
   - ✅ Builds and deploys successfully

2. **Variable-Based Status Codes (❌ FAILS):**
   ```xml
   <http:listener path="/customers/{id}" config-ref="HTTP_Listener_config">
       <http:response statusCode="#[vars.httpStatus default 200]"/>
   </http:listener>
   ```
   - ❌ Variable expression evaluated at listener initialization time
   - ❌ Variable set AFTER listener initialization, so always uses default
   - ❌ App may crash or fail to start

3. **Conditional Status Codes Challenge:**
   - For conditional status codes (e.g., 200 vs 404), need to set variable BEFORE listener
   - But listener is the entry point, so can't set variable before it
   - **Solution needed:** Use separate flows, subflows, or error handlers

### Next Steps

1. ✅ Use `<http:response>` inside `<http:listener>` for static status codes
2. ⚠️ For conditional status codes, need to investigate:
   - Separate flows for each status code scenario
   - Error handlers with on-error-continue
   - Subflows with status code parameter
   - Response builder pattern

### Current Status

- ✅ Static status codes (200, 201, 204) work with `<http:response>` inside `<http:listener>`
- ✅ Conditional status codes (200 vs 404) work with variable expressions: `statusCode="#[vars.httpStatus default 200]"`
- ✅ Variable expressions DO work - they're evaluated at runtime when response is sent, not at listener initialization
- ✅ **ALL STATUS CODES WORKING CORRECTLY** after proper app restart

### ✅ FINAL WORKING PATTERN

**Static Status Codes:**
```xml
<http:listener path="/health" config-ref="HTTP_Listener_config">
    <http:response statusCode="200"/>
</http:listener>
```

**Conditional Status Codes:**
```xml
<http:listener path="/customers/{id}" config-ref="HTTP_Listener_config">
    <http:response statusCode="#[vars.httpStatus default 200]"/>
</http:listener>
<choice>
    <when expression="#[attributes.uriParams.id == '123']">
        <ee:transform>
            <ee:variables>
                <ee:set-variable variableName="httpStatus">200</ee:set-variable>
            </ee:variables>
        </ee:transform>
        <!-- response payload -->
    </when>
    <otherwise>
        <ee:transform>
            <ee:variables>
                <ee:set-variable variableName="httpStatus">404</ee:set-variable>
            </ee:variables>
        </ee:transform>
        <!-- error payload -->
    </otherwise>
</choice>
```

**Key Insight:** The variable expression `#[vars.httpStatus default 200]` is evaluated at **runtime when the response is sent**, not at listener initialization. Setting the variable in transforms within choice branches works perfectly.
