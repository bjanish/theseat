# Deploy The Seat Landing Page (GitHub Pages + theseat.us)

## What was done locally

The site files were placed in a folder with no space, ready to push to a dedicated site repo. The folder was renamed from `The Seat` to `theseat-site` (no space) and a `CNAME` file was added for the domain, so the folder's contents are root-ready.

This only renamed the local folder and added one file. It did NOT create or push any GitHub repo — that part is done by hand.

## Current state of the folder

The folder is `theseat-site/` with four files, all root-ready:

```
theseat-site/
├── index.html   (paths are local: chair.png, favicon.png)
├── chair.png
├── favicon.png
└── CNAME        (contains: theseat.us)
```

No spaces anywhere, paths resolve, and `CNAME` tells GitHub Pages the custom domain.

## Next steps (outside this repo)

1. Create a **new, separate** GitHub repo — e.g. `theseat-site` — so you're not serving your app source.
2. Copy the **contents** of this `theseat-site/` folder into that new repo's root (the four files, not the folder itself).
3. Push it to `main`.
4. Repo → Settings → Pages → deploy from `main`, root. It'll detect the CNAME and set the custom domain to `theseat.us`.
5. At your DNS provider for `theseat.us`, set the four apex A records (see DNS section below — this is a REPLACE, not a fresh add):
   - `185.199.108.153`
   - `185.199.109.153`
   - `185.199.110.153`
   - `185.199.111.153`
6. Back in Settings → Pages, tick "Enforce HTTPS" once the cert provisions (can take a bit after DNS propagates).

## DNS — IMPORTANT: this is a REPLACE, not a fresh add

As of setup, `theseat.us` already resolves — but to AWS/registrar parking IPs, NOT GitHub:
- `13.248.243.5`
- `76.223.105.230`

The domain is registered and has active A records pointing to a parking/landing page. So at the DNS provider you must:

1. **DELETE** the two existing A records (`13.248.243.5`, `76.223.105.230`)
2. **ADD** the four GitHub apex A records:
   - `185.199.108.153`
   - `185.199.109.153`
   - `185.199.110.153`
   - `185.199.111.153`
3. Optionally **ADD** a `www` CNAME → `<username>.github.io`
4. Optionally add GitHub's AAAA (IPv6) records:
   - `2606:50c0:8000::153`
   - `2606:50c0:8001::153`
   - `2606:50c0:8002::153`
   - `2606:50c0:8003::153`

Because the old IPs are already cached, the change may take time to propagate as the old records age out (governed by TTL). Lower the TTL first if possible so the switch happens faster.

Verify the switch with:
```
dig theseat.us +short
```
When it returns the four `185.199.x.153` addresses instead of the AWS IPs, DNS is pointed at GitHub.

## Notes

- The renamed folder is a staged change in *this* app repo. It's not committed. Leave it staged or handle it however you like when you next commit.
- The App Store badge in `index.html` links to `#` — swap in the real App Store URL after approval.
- For an apex domain (`theseat.us`) use the four A records above. If you ever use `www.theseat.us` instead, that's a single CNAME record pointing to `<username>.github.io`.
