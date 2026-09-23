# Recon Checklist — {program}

Reference: `knowledge-base/recon/recon-playbook.md`. Mark traffic with the platform's required header.

## Passive
- [ ] subfinder + amass (passive) + crt.sh → `subdomains-all.txt`
- [ ] Live host probe (httpx) → `live-hosts.txt`, `live-urls.txt`
- [ ] Flag interesting hosts (admin/api/dev/staging/internal)
- [ ] Wayback URLs → params + JS split
- [ ] gf patterns over params (xss ssrf sqli redirect idor lfi rce ssti)
- [ ] Review JS files for endpoints and secrets

## Active (confirm the brief allows it)
- [ ] Content discovery (ffuf) on priority hosts
- [ ] Nuclei conservative pass (`-rl 30`, misconfig/exposure/takeover)

## Surface mapping
- [ ] Auth flow mapped (login, register, reset, 2FA, OAuth/SAML, session type)
- [ ] Object-ID scheme identified (numeric / UUID / slug)
- [ ] State-changing actions listed
- [ ] Integrations noted (webhooks, import/export, PDF/image gen)
- [ ] Tech stack recorded in program README

## Output review
- [ ] `recon/summary.md` read
- [ ] Top 5 leads written into HANDOFF
- [ ] Priority test list set
