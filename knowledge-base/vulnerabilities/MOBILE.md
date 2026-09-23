# Mobile App Testing (Android / iOS)

> Severity: Low–Critical  ·  Translate to any platform via `framework/severity-mapping.md`.
> (Inline P1–P5 references below are Bugcrowd VRT — map them the same way.)
> **Key insight:** The app itself is recon. The real bugs are on the backend API it talks to.

---

## The Right Mental Model

Mobile apps are not the target — they are a **recon tool** for finding:
- Hidden API endpoints not documented anywhere
- Parameters the web app doesn't expose
- Hardcoded secrets (API keys, tokens, internal URLs)
- Auth flows unique to the mobile client

Test the backend API the app talks to. That's where the money is.

---

## Android Testing

### Step 1: Get the APK

```bash
# From device (if installed)
adb shell pm list packages | grep "target"
adb shell pm path com.target.app
adb pull /data/app/com.target.app/base.apk target.apk

# Or download from APKPure / APKMirror for the official version
```

### Step 2: Static Analysis — Decompile and Search

```bash
# Decompile with jadx
jadx -d target-decompiled/ target.apk

# Now search for high-value strings
cd target-decompiled/

# API endpoints
grep -rE "https?://[a-zA-Z0-9./_-]+" --include="*.java" | sort -u > endpoints.txt
grep -rE "/api/v[0-9]" --include="*.java" | sort -u >> endpoints.txt

# Hardcoded secrets
grep -rE "(api_key|apikey|secret|token|password|passwd|private_key|access_key)" \
  --include="*.java" -i | grep -v "//.*comment"

# AWS keys
grep -rE "AKIA[0-9A-Z]{16}" --include="*.java" --include="*.xml" --include="*.json"

# Internal URLs / staging environments
grep -rE "(staging|internal|dev|test|localhost|127\.0\.0\.1|192\.168)" \
  --include="*.java" --include="*.xml" -i

# Firebase config (common misconfiguration)
grep -rE "firebase|firebaseio\.com" --include="*.java" --include="*.xml" -i

# Weak crypto
grep -rE "(MD5|SHA1|DES|RC4|ECB)" --include="*.java" -i
```

### Step 3: Check AndroidManifest.xml

```bash
cat target-decompiled/resources/AndroidManifest.xml | grep -E \
  "android:exported|android:permission|android:debuggable|android:allowBackup"

# Flags to look for:
# android:debuggable="true"    → debug mode in production (bad)
# android:allowBackup="true"   → app data can be backed up / extracted
# android:exported="true"      → Activity/Service reachable from other apps
# Missing android:permission on exported components → component hijacking
```

### Step 4: Dynamic Analysis — Proxy Through Burp

```bash
# Install Burp cert on device
# Settings → Security → Install certificate → burp.der

# For certificate pinning bypass — use Frida
frida -U -f com.target.app --codeshare sowdust/universal-android-ssl-pinning-bypass-with-frida

# Or use objection
objection -g com.target.app explore
# Inside objection:
android sslpinning disable
```

### Step 5: Check Local Storage

```bash
# Pull app data (rooted device or emulator)
adb shell
run-as com.target.app
ls -la /data/data/com.target.app/

# Check these locations:
# shared_prefs/    → SharedPreferences (often stores tokens insecurely)
# databases/       → SQLite databases (may contain sensitive data)
# files/           → Downloaded files, cached data
# cache/           → HTTP cache (may contain sensitive responses)

# Pull and read SharedPreferences
cat /data/data/com.target.app/shared_prefs/*.xml | grep -iE "token|key|password|user"
```

---

## iOS Testing

### Step 1: Get the IPA

```bash
# From a jailbroken device using frida-ios-dump
python3 dump.py -H 127.0.0.1 -p 2222 com.target.app
```

### Step 2: Static Analysis

```bash
# Extract IPA
unzip target.ipa -d target-extracted/

# Find the binary
find target-extracted/ -name "*.app" -type d

# Decrypt and analyze binary strings
strings Payload/Target.app/Target | grep -iE \
  "(api|https?://|secret|token|key|password|endpoint)"

# Use class-dump to extract Objective-C class definitions
class-dump -H Payload/Target.app/Target -o headers/

# Search headers for interesting method names
grep -rE "(admin|internal|debug|secret|auth|login|payment)" headers/
```

### Step 3: Dynamic Analysis with Frida / Objection

```bash
# Start objection
objection -g com.target.app explore

# Disable SSL pinning
ios sslpinning disable

# List keychain contents
ios keychain dump

# Watch filesystem access in real time
ios monitor filesystem
```

---

## What to Look for in Mobile Traffic (Burp)

Once you have the app proxied through Burp, treat the backend API as the real target:

- [ ] Endpoints not visible in web version → test for IDOR, missing auth
- [ ] Mobile-specific API version (`/api/mobile/` or `/v2/`) → may have different auth rules
- [ ] Parameters not in web requests → test for mass assignment
- [ ] `X-App-Version` or `X-Platform: mobile` headers → try removing them (some checks bypass if header is missing)
- [ ] Hardcoded device IDs used as auth → predictable?
- [ ] JWT tokens → decode and check algorithm, expiry, role claims

---

## Quick Win Checklist

- [ ] APK decompiled and searched for API keys / internal URLs
- [ ] AndroidManifest.xml checked for debug mode + exported components
- [ ] SSL pinning bypassed — all traffic visible in Burp
- [ ] Local storage checked for sensitive data (tokens, PII)
- [ ] Mobile-specific API endpoints tested for IDOR
- [ ] Mobile API version compared to web API — different auth rules?

---

## Severity Examples

| Finding | Severity |
|---------|---------|
| Hardcoded API key with write access | P1–P2 |
| Sensitive data in local storage (unencrypted tokens) | P2–P3 |
| SSL pinning bypassable (alone) | P4 — informational |
| IDOR on mobile-specific endpoint | P2 |
| Exported Activity accessible without permission | P2–P3 |
| Debug mode enabled in production APK | P3–P4 |
| Backup allowed (sensitive data extractable) | P3 |

---

## Tools Summary

| Tool | Purpose |
|------|---------|
| `jadx` | Android APK decompiler |
| `apktool` | APK unpacking + resource extraction |
| `frida` | Dynamic instrumentation (runtime hooking) |
| `objection` | Frida-based mobile exploration shell |
| `MobSF` | Automated static + dynamic analysis |
| `class-dump` | iOS Objective-C header extraction |
| Burp Suite | Traffic interception and analysis |

## Resources
- [OWASP MASTG](https://mas.owasp.org/MASTG/) — Mobile Application Security Testing Guide
- [OWASP MASVS](https://mas.owasp.org/MASVS/) — Mobile security requirements
- [HackTricks Android](https://book.hacktricks.xyz/mobile-pentesting/android-app-pentesting)
- [HackTricks iOS](https://book.hacktricks.xyz/mobile-pentesting/ios-pentesting)
