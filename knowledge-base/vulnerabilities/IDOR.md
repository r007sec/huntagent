# IDOR — Insecure Direct Object Reference

> **Severity:** P2–P3 (P1 if account takeover possible)  
> **Frequency:** Very common across all platforms  
> **Payout range:** $100–$3,000+

---

## What It Is

IDOR occurs when an application uses user-controlled input to access objects (records, files, functions) without verifying the requester is authorized. You change an ID, and you get someone else's data.

---

## Where to Look

### High-Value Targets (P1/P2)
- Password reset endpoints (change user ID → reset someone else's password)
- Account settings / profile updates (change email, phone)
- Payment/billing information
- Admin functions with numeric IDs
- API endpoints: `/api/v1/users/{id}`, `/api/orders/{id}`
- File downloads with predictable paths
- Export/report generation

### Medium-Value (P2/P3)
- View other users' data (orders, messages, documents)
- Invoice/receipt access
- Notification settings of other users
- Activity logs of other users

### Lower Value (P3/P4)
- Viewing non-sensitive public-ish data
- Usernames, profile pictures of other users

---

## Testing Approach

### 1. Create Two Accounts
Always test IDOR with **two separate accounts** (Account A and Account B):
- Create both accounts with different browsers or Burp profiles
- Use Account A to create resources, capture the IDs
- Use Account B to try accessing those IDs

### 2. Identify Object References
Look for IDs in:
```
- URL parameters: ?user_id=123, /profile/123
- Request body: {"user_id": 123, "order_id": "abc-def"}
- Headers: X-User-ID: 123
- Cookies: session data containing IDs
- Response bodies (use these IDs in subsequent requests)
```

### 3. Substitution Techniques
```
# Numeric IDs: increment/decrement
/api/users/1000 → /api/users/999, /api/users/1001

# UUIDs: swap with Account B's UUID
# Find Account B's UUID from their own session

# Encoded IDs: decode first
base64: dXNlcl8xMjM= → user_123
→ try user_124, user_122

# Hashed IDs: if MD5/SHA1 of predictable value
```

### 4. HTTP Method Manipulation
If GET is protected, try PUT, POST, DELETE, PATCH:
```
GET /api/users/123/data → 403
POST /api/users/123/data → 200 (?!)
```

### 5. Parameter Pollution
```
GET /api/orders?id=MY_ID&id=VICTIM_ID
POST body: user_id=MY_ID&user_id=VICTIM_ID
```

### 6. Nested Object IDOR
```
# Your object: /api/users/ME/documents/YOUR_DOC_ID
# Try:         /api/users/VICTIM/documents/YOUR_DOC_ID
# Or:          /api/users/ME/documents/VICTIM_DOC_ID
```

---

## Common Bypass Techniques

| Filter | Bypass |
|--------|--------|
| ID ownership check on GET only | Use POST/PUT/DELETE |
| Checking parent object only | IDOR on child object |
| Integer IDs only | Look for secondary UUID reference |
| Authorization header checked | Try removing the header entirely |
| Rate limiting | Slow down, use different IPs |

---

## Proof of Concept Requirements

A strong IDOR PoC needs:
1. **Account A** credentials (attacker) — or clearly labeled "Attacker"
2. **Account B** ID/email (victim) — what you used to set up the target
3. **The exact request** showing Account A accessing Account B's resource
4. **The response** showing Account B's data returned
5. **Business impact statement** — what can an attacker actually do with this?

---

## Impact Escalation (Makes It Worth More)

- Can you **modify** data, not just read? (Higher severity)
- Can you **delete** Account B's resources?
- Can you perform **account takeover** via IDOR?
- Can you access **admin-only** resources?
- Does the data contain **PII, payment info, credentials**?

---

## Report Tips

- Severity (translate per `framework/severity-mapping.md`): High for sensitive data read, Critical for account takeover, Medium for non-sensitive
- Always show **actual data returned**, not just a 200 response code
- State the **number of users potentially affected**
- Mention if **no authorization check exists at all** vs. **authorization bypassable**

---

## Resources

- [OWASP IDOR](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/05-Authorization_Testing/04-Testing_for_Insecure_Direct_Object_References)
- [PayloadsAllTheThings - IDOR](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Insecure%20Direct%20Object%20References)
