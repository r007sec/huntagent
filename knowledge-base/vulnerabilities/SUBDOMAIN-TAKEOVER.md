# Subdomain Takeover

> Severity: Medium–High (High when it enables auth/cookie theft or phishing on the real domain)
> Scanner-blind: partly automatable and fast — good early-recon win.
> Translate severity via `framework/severity-mapping.md`.

A subdomain points (CNAME/A) at a third-party service that is no longer claimed. Register the service
with that name and you control content on the target's subdomain.

## Where to look

From recon (`../recon/recon-playbook.md`), any subdomain whose DNS points at a service:
- Cloud/storage: S3, Azure Blob, Google Cloud Storage
- PaaS/hosting: Heroku, GitHub Pages, GitLab Pages, Netlify, Vercel, Fastly, Surge
- SaaS: Shopify, Zendesk, Desk, Statuspage, Helpscout, Cargo, Unbounce, Wufoo, Tumblr

## Test cases

```bash
# Flag dangling CNAMEs across your subdomain list
subzy run --targets subdomains-all.txt
nuclei -l live-urls.txt -t ~/nuclei-templates/http/takeovers/ -H "<id-header>"

# Manual check
dig CNAME sub.target.com          # where does it point?
curl -sI https://sub.target.com    # fingerprint the "not claimed" error page
```

The tell is a service's default "no such bucket / no app here / 404 from provider" page on a
subdomain that still resolves.

## Confirm it's real

**Actually claim it** (register the S3 bucket / Heroku app / Pages repo with the exact name) and
serve a benign proof file at a unique path — do not leave malicious content up, and remove it after.
A fingerprint alone is a strong LEAD; a served proof page is CONFIRMED. Some providers' "unclaimed"
pages are not actually claimable — verify the specific service is takeover-able, not just erroring.

## Report tips

- State the exact subdomain, the service it dangles to, and that you served a proof file (include its
  URL/screenshot), then removed it.
- Impact: content control on the target's domain enables convincing phishing and, if cookies are
  scoped to the parent domain, session theft — say which applies here.

## Resources

- [Can I take over XYZ?](https://github.com/EdOverflow/can-i-take-over-xyz)
