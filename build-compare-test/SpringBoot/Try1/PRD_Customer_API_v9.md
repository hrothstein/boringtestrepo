# Product Requirements Document

**Customer Management API — AI Development Comparison Study**

---

**Document Version:** 9.0  
**Author:** Howie Ross, Sr. Director Solution Engineering  
**Date:** January 2026  
**Scope:** LOCAL BUILD AND TEST ONLY  
**Runtime:** Claude Code with exact token tracking

---

> **Repository:** `https://github.com/hrothstein/boringtestrepo.git`

---

## Experiment Purpose

Compare AI-assisted development of identical Customer Management APIs using MuleSoft versus Spring Boot. Measure:
- **Exact token usage** (primary metric)
- Time to working code
- Debug iterations
- Manual interventions

---

## Attempt History (MuleSoft)

| Attempt | Outcome | Failure Reason |
|---------|---------|----------------|
| 1 | FAILED | Fabricated metrics, no actual execution |
| 2 | FAILED | All status codes returned 200, wrong repo push |
| 3 | SUCCESS | Used verified `<http:response>` pattern inside `<http:listener>` |
| 4 | SUCCESS | Claude Code run — ~3.5 min, 1 debug iteration, 10/10 tests |

---

## What We Are Testing

| Checkpoint | MuleSoft | Spring Boot |
|------------|----------|-------------|
| Build | MuleSoft MCP Server | `mvn clean compile` |
| Test | MuleSoft MCP Server | `mvn test` |
| Run Locally | MuleSoft MCP Server | `mvn spring-boot:run` |
| Verify Endpoints | `curl localhost:8081` | `curl localhost:8080` |

> 🚫 **NO CLOUDHUB. NO ANYPOINT PLATFORM. LOCAL DEPLOYMENT ONLY.**

---

## Metrics to Capture

| Metric | How Measured |
|--------|--------------|
| **Total input tokens** | Claude Code session log extraction |
| **Total output tokens** | Claude Code session log extraction |
| **Total tokens** | Claude Code session log extraction |
| Time to working build | Timestamp delta |
| Time to passing tests | Timestamp delta |
| Time to correct status codes | Timestamp delta |
| Debug iterations | Count of error-fix-retry cycles |
| Manual interventions | Count of human corrections |
| Tests passed | Actual test runner output |

---

## Application Specification

### Endpoints with Required Status Codes

| Method | Path | Success | Failure |
|--------|------|---------|---------|
| GET | /customers | 200 OK | - |
| GET | /customers/{id} | 200 OK | 404 Not Found |
| POST | /customers | 201 Created | 400 Bad Request |
| PUT | /customers/{id} | 200 OK | 400/404 |
| DELETE | /customers/{id} | 204 No Content | 404 Not Found |
| GET | /health | 200 OK | - |

### Data Model

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| id | UUID | Auto | System generated |
| firstName | String | Yes | 1-50 characters |
| lastName | String | Yes | 1-50 characters |
| email | String | Yes | Valid format, unique |
| phone | String | No | E.164 format |
| accountStatus | Enum | Yes | ACTIVE, INACTIVE, SUSPENDED |
| createdAt | DateTime | Auto | ISO 8601 |
| updatedAt | DateTime | Auto | ISO 8601 |

### Requirements

- Input validation on required fields
- Consistent error format: `{ "error": "...", "message": "..." }`
- No stack traces in error responses
- In-memory storage (mock data acceptable)

---

## Required Output Files

### results/phases.json

```json
{
  "framework": "MuleSoft|SpringBoot",
  "start_time": "<actual>",
  "end_time": "<actual>",
  "checkpoints": {
    "build": { "passed": true/false, "timestamp": "<actual>" },
    "tests": { "passed": true/false, "total": N, "passed_count": N, "failed_count": N },
    "deploy": { "passed": true/false, "timestamp": "<actual>" },
    "health_check": { "passed": true/false, "status_code": <actual> },
    "status_codes_correct": { "passed": true/false },
    "all_endpoints": { "passed": true/false, "verified_count": N }
  },
  "debug_iterations": <count>,
  "errors_encountered": ["<list>"]
}
```

### results/endpoint-tests.json

```json
{
  "app_running": true,
  "base_url": "http://localhost:808X",
  "tests": [
    {
      "endpoint": "GET /health",
      "expected_status": 200,
      "actual_status": <actual>,
      "status_correct": true/false,
      "actual_response": "<paste actual>"
    }
  ],
  "summary": {
    "total_tests": N,
    "passed": N,
    "failed": N,
    "pass_rate": "X%"
  }
}
```

### results/token-usage.json

```json
{
  "framework": "MuleSoft|SpringBoot",
  "session_timestamp": "<actual>",
  "input_tokens": <uncached>,
  "output_tokens": <actual>,
  "cache_creation_input_tokens": <actual>,
  "cache_read_input_tokens": <actual>,
  "total_input_tokens": <input + cache_creation + cache_read>,
  "total_tokens": <total_input + output>
}
```

### learnings.md

Document any errors encountered and solutions found.

---

# MuleSoft Implementation Prompt

```
You are building a Customer Management API using MuleSoft.

REPOSITORY: https://github.com/hrothstein/boringtestrepo.git
BRANCH: mulesoft-v4

=====================================================================
CRITICAL: HTTP STATUS CODE PATTERN (VERIFIED WORKING)
=====================================================================

The ONLY way to set HTTP status codes in Mule is to nest
<http:response> INSIDE the <http:listener> element:

✅ CORRECT PATTERN:
<http:listener path="/customers" config-ref="HTTP_Listener_config" allowedMethods="POST">
    <http:response statusCode="#[vars.httpStatus default 200]" />
</http:listener>

Then set the variable in your flow:
<set-variable variableName="httpStatus" value="201" />

The listener reads vars.httpStatus at runtime and applies it.

❌ WRONG (will fail or be ignored):
- <http:response> after <ee:transform>
- <http:response> outside the listener
- <ee:set-attributes> for status codes

Use this pattern for ALL endpoints.

=====================================================================
MANDATORY: USE MULESOFT MCP SERVER
=====================================================================

You have access to the MuleSoft MCP Server. Use it for:
- Creating the project
- Building the application
- Deploying LOCALLY to http://localhost:8081
- Testing endpoints

Do not use Maven directly. Use MCP Server tools.

=====================================================================
GIT SAFETY
=====================================================================

BEFORE ANY COMMIT OR PUSH:
1. Run: git remote -v
2. Verify remote is: https://github.com/hrothstein/boringtestrepo.git
3. Run: git branch
4. Verify you are on branch: mulesoft-v4
5. If wrong, STOP and fix it

=====================================================================
SIMPLIFIED SCOPE: MOCK DATA
=====================================================================

Use MOCK DATA. No Object Store. No persistence.

- GET /customers → Return hardcoded array of 2 customers (200)
- GET /customers/{id} → If id="123" return customer (200), else 404
- POST /customers → Return input + generated UUID (201)
- PUT /customers/{id} → If id="123" return updated (200), else 404
- DELETE /customers/{id} → If id="123" return 204, else 404
- GET /health → Return {"status": "UP"} (200)

=====================================================================
CHECKPOINTS
=====================================================================

1. PROJECT CREATED - Confirm structure exists
2. BUILD SUCCEEDS - Paste actual output
3. DEPLOY LOCALLY - App running at localhost:8081
4. HEALTH CHECK - GET /health returns 200
5. STATUS CODES CORRECT:
   - POST returns 201 (not 200)
   - GET /customers/bad-id returns 404 (not 200)
   - DELETE /customers/123 returns 204 (not 200)
6. ALL ENDPOINTS WORK - Full CRUD cycle verified

=====================================================================
DO NOT
=====================================================================

- Fabricate test results
- Place <http:response> outside the listener
- Use <ee:set-attributes> for status codes
- Deploy to CloudHub
- Return 200 for everything
- Stop until all checkpoints pass

=====================================================================
LEARNING LOG
=====================================================================

Create learnings.md and document any errors + solutions.

=====================================================================
OUTPUT FILES
=====================================================================

Create in results/ folder:
- phases.json
- endpoint-tests.json
- token-usage.json (populate at end using extraction commands below)

=====================================================================
TOKEN TRACKING — EXACT METRICS (CRITICAL)
=====================================================================

Claude Code does NOT have direct access to token counts during a session.
To get exact token metrics, extract them from the session log file.

AT THE END OF THIS SESSION, run these commands:

# Step 1: Find current session file (most recently modified)
ls -lt ~/.claude/projects/*/ | head -5

# Step 2: Set the session file path (replace with actual path from Step 1)
SESSION_FILE=~/.claude/projects/<path>/<session>.jsonl

# Step 3: Extract each metric
# Input tokens (uncached)
grep -o '"input_tokens":[0-9]*' $SESSION_FILE | cut -d: -f2 | awk '{sum+=$1} END {print sum}'

# Output tokens
grep -o '"output_tokens":[0-9]*' $SESSION_FILE | cut -d: -f2 | awk '{sum+=$1} END {print sum}'

# Cache creation tokens
grep -o '"cache_creation_input_tokens":[0-9]*' $SESSION_FILE | cut -d: -f2 | awk '{sum+=$1} END {print sum}'

# Cache read tokens
grep -o '"cache_read_input_tokens":[0-9]*' $SESSION_FILE | cut -d: -f2 | awk '{sum+=$1} END {print sum}'

# Step 4: Update results/token-usage.json with ACTUAL values:
{
  "framework": "MuleSoft",
  "session_timestamp": "<actual>",
  "input_tokens": <from grep command>,
  "output_tokens": <from grep command>,
  "cache_creation_input_tokens": <from grep command>,
  "cache_read_input_tokens": <from grep command>,
  "total_input_tokens": <input + cache_creation + cache_read>,
  "total_tokens": <total_input + output>
}

DO NOT leave placeholder values. This is the PRIMARY METRIC.
DO NOT finish until token-usage.json has real numbers.

=====================================================================
SUCCESS CRITERIA
=====================================================================

DONE when:
[ ] App runs at localhost:8081
[ ] Health returns 200
[ ] POST /customers returns 201
[ ] GET /customers/bad-id returns 404
[ ] DELETE /customers/123 returns 204
[ ] All results files have actual data
[ ] token-usage.json has EXACT token counts (not placeholders)
```

---

# Spring Boot Implementation Prompt

```
You are building a Customer Management API using Spring Boot 3.x.

REPOSITORY: https://github.com/hrothstein/boringtestrepo.git
BRANCH: springboot-v2

=====================================================================
SCOPE: LOCAL BUILD AND TEST ONLY
=====================================================================

Use Maven to:
1. Build the project: mvn clean compile
2. Run tests: mvn test
3. Run locally: mvn spring-boot:run
4. Verify endpoints with curl

NO containerization. NO cloud deployment. Just local.

=====================================================================
GIT SAFETY
=====================================================================

BEFORE ANY COMMIT OR PUSH:
1. Run: git remote -v
2. Verify remote is: https://github.com/hrothstein/boringtestrepo.git
3. Run: git branch
4. Verify you are on branch: springboot-v2
5. If wrong, STOP and fix it

=====================================================================
SIMPLIFIED SCOPE: MOCK DATA
=====================================================================

Use MOCK DATA. No database. No persistence.

- GET /customers → Return hardcoded array of 2 customers (200)
- GET /customers/{id} → If id="123" return customer (200), else 404
- POST /customers → Return input + generated UUID (201)
- PUT /customers/{id} → If id="123" return updated (200), else 404
- DELETE /customers/{id} → If id="123" return 204, else 404
- GET /actuator/health → Health check (200)

=====================================================================
IMPLEMENTATION REQUIREMENTS
=====================================================================

- Spring Boot 3.x with Spring Web
- Input validation using jakarta.validation
- Consistent error response via @ControllerAdvice
- No stack traces in errors
- Spring Actuator for health endpoint
- Correct HTTP status codes using ResponseEntity

=====================================================================
CHECKPOINTS
=====================================================================

1. PROJECT CREATED - Confirm structure exists
2. BUILD SUCCEEDS - mvn clean compile shows BUILD SUCCESS
3. TESTS PASS - mvn test shows results
4. APP RUNS - localhost:8080 responds
5. HEALTH CHECK - GET /actuator/health returns 200
6. STATUS CODES CORRECT:
   - POST returns 201 (not 200)
   - GET /customers/bad-id returns 404 (not 200)
   - DELETE /customers/123 returns 204 (not 200)
7. ALL ENDPOINTS WORK - Full CRUD cycle verified

=====================================================================
DO NOT
=====================================================================

- Fabricate test results
- Skip checkpoints
- Return 200 for everything
- Stop until all checkpoints pass

=====================================================================
LEARNING LOG
=====================================================================

Create learnings.md and document any errors + solutions.

=====================================================================
OUTPUT FILES
=====================================================================

Create in results/ folder:
- phases.json
- endpoint-tests.json
- token-usage.json (populate at end using extraction commands below)

=====================================================================
TOKEN TRACKING — EXACT METRICS (CRITICAL)
=====================================================================

Claude Code does NOT have direct access to token counts during a session.
To get exact token metrics, extract them from the session log file.

AT THE END OF THIS SESSION, run these commands:

# Step 1: Find current session file (most recently modified)
ls -lt ~/.claude/projects/*/ | head -5

# Step 2: Set the session file path (replace with actual path from Step 1)
SESSION_FILE=~/.claude/projects/<path>/<session>.jsonl

# Step 3: Extract each metric
# Input tokens (uncached)
grep -o '"input_tokens":[0-9]*' $SESSION_FILE | cut -d: -f2 | awk '{sum+=$1} END {print sum}'

# Output tokens
grep -o '"output_tokens":[0-9]*' $SESSION_FILE | cut -d: -f2 | awk '{sum+=$1} END {print sum}'

# Cache creation tokens
grep -o '"cache_creation_input_tokens":[0-9]*' $SESSION_FILE | cut -d: -f2 | awk '{sum+=$1} END {print sum}'

# Cache read tokens
grep -o '"cache_read_input_tokens":[0-9]*' $SESSION_FILE | cut -d: -f2 | awk '{sum+=$1} END {print sum}'

# Step 4: Update results/token-usage.json with ACTUAL values:
{
  "framework": "SpringBoot",
  "session_timestamp": "<actual>",
  "input_tokens": <from grep command>,
  "output_tokens": <from grep command>,
  "cache_creation_input_tokens": <from grep command>,
  "cache_read_input_tokens": <from grep command>,
  "total_input_tokens": <input + cache_creation + cache_read>,
  "total_tokens": <total_input + output>
}

DO NOT leave placeholder values. This is the PRIMARY METRIC.
DO NOT finish until token-usage.json has real numbers.

=====================================================================
SUCCESS CRITERIA
=====================================================================

DONE when:
[ ] Build succeeds
[ ] Tests pass
[ ] App runs at localhost:8080
[ ] Health returns 200
[ ] POST /customers returns 201
[ ] GET /customers/bad-id returns 404
[ ] DELETE /customers/123 returns 204
[ ] All results files have actual data
[ ] token-usage.json has EXACT token counts (not placeholders)
```

---

## Evaluation

After both complete, compare:

| Metric | MuleSoft | Spring Boot |
|--------|----------|-------------|
| Total tokens | | |
| Input tokens | | |
| Output tokens | | |
| Cache tokens | | |
| Time to working code | | |
| Debug iterations | | |
| Manual interventions | | |
| Tests passed | | |

---

## Qualitative (After Both Run)

Once both work locally with correct status codes:

- How to make discoverable in API catalog?
- How to add rate limiting without code changes?
- How to expose to AI agents?
- How to version/deprecate?

MuleSoft answers with platform features. Spring Boot requires additional work.

---

*— End of Document —*
