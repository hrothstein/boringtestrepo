# MuleSoft Customer Management API - Learnings

## Project Overview
This document captures errors encountered and solutions found during the implementation of the Customer Management API using MuleSoft.

## Errors and Solutions

### 1. mule-ee-core Dependency Error

**Error:**
```
Could not find artifact org.mule.modules:mule-ee-core:jar:mule-plugin:4.10.0
```

**Cause:** 
Initially added `mule-ee-core` as a dependency thinking it was required for DataWeave transforms.

**Solution:**
Removed the dependency. The `mule-ee-core` module is already provided by the Mule Enterprise runtime and doesn't need to be declared in pom.xml.

### 2. HTTP Status Code Pattern

**Learning:**
The correct way to set HTTP status codes in Mule 4 is to:
1. Nest `<http:response statusCode="#[vars.httpStatus default 200]" />` INSIDE the `<http:listener>` element
2. Use `<set-variable variableName="httpStatus" value="XXX"/>` in the flow to set the status code

**Example:**
```xml
<http:listener config-ref="HTTP_Listener_config" path="/customers" allowedMethods="POST">
    <http:response statusCode="#[vars.httpStatus default 200]">
        <http:headers>#[{'Content-Type': 'application/json'}]</http:headers>
    </http:response>
</http:listener>
<set-variable variableName="httpStatus" value="201" doc:name="Set Status 201"/>
```

### 3. DataWeave for JSON Responses

**Learning:**
Using `ee:transform` with DataWeave 2.0 is the cleanest way to construct JSON responses:

```xml
<ee:transform doc:name="Response">
    <ee:message>
        <ee:set-payload><![CDATA[%dw 2.0
output application/json
---
{
    "status": "UP"
}]]></ee:set-payload>
    </ee:message>
</ee:transform>
```

### 4. Choice Router for Conditional Logic

**Learning:**
The `<choice>` element works well for implementing conditional logic like ID checking:

```xml
<choice doc:name="Check Customer ID">
    <when expression="#[vars.customerId == '123']">
        <!-- Found case -->
    </when>
    <otherwise>
        <!-- Not found case - set 404 -->
    </otherwise>
</choice>
```

## Best Practices Identified

1. **Use property placeholders** for configurable values like ports and hosts
2. **Keep global configurations** in a separate global.xml file
3. **Use config.properties** for environment-specific values
4. **Set default values** in DataWeave expressions to handle null cases

## Success Metrics

- All 6 endpoints implemented and working
- Correct HTTP status codes: 200, 201, 204, 400, 404
- Validation working for required fields
- Mock data returning expected structure
