# File Upload Flaws

> Severity: Medium–Critical (stored XSS to RCE)
> Scanner-blind: partly. High-value when uploads are processed or served.
> Translate severity via `framework/severity-mapping.md`.

## Where to look

Avatars, documents, imports, attachments, logos, resume/CV uploads, image processing, anything that
takes a file and later serves or processes it.

## Test cases

- **Extension / content-type bypass**: `.php`, `.phtml`, `.jsp`, `.asp`, double extensions
  (`shell.php.jpg`), null byte (`shell.php%00.jpg`), case (`.PhP`), trailing dot/space, alternate
  (`.php5`, `.pht`). Change `Content-Type` to `image/jpeg` while sending code.
- **Magic-byte spoof**: prepend real image bytes (`GIF89a;`) before your payload to pass content
  sniffing.
- **SVG → stored XSS / SSRF / XXE**: SVGs are XML and render in-browser. Embed
  `<script>`/`<image href=...>` (XSS) or an external entity (XXE). One of the highest-yield upload
  bugs because "image upload" is rarely locked down for SVG.
- **Path traversal in filename**: `../../../etc/uploads/x` to write outside the intended dir.
- **Overwrite**: upload with an existing critical filename if names aren't randomized.
- **Image parsers**: ImageMagick/GraphicsMagick (ImageTragick), polyglot files, EXIF-based injection.
- **Client-side-only validation**: strip the JS check; the server may accept anything.
- **XXE via DOCX/XLSX/PDF** processing (Office files are ZIP+XML).

## Malicious SVG (XSS) sample

```xml
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" onload="alert(document.domain)"/>
```

## Confirm it's real

- For code execution: the uploaded file must be **served and executed** by the server (browse to it,
  get your callback / command output), not just stored.
- For SVG XSS: it must execute in a **victim-relevant origin** when the file is viewed, not only when
  you open the raw file locally (`../false-positive-traps.md`).

## Report tips

- State where the file is served from and that it executes in the app's origin.
- Keep the PoC benign: `alert(document.domain)` or a callback, never a real web shell against prod.

## Resources

- [OWASP — Unrestricted File Upload](https://owasp.org/www-community/vulnerabilities/Unrestricted_File_Upload)
