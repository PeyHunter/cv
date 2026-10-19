# Peyton Hunter · CV

Live at **https://cv.peytonhunter.com**. Every version is also a [GitHub Release](https://github.com/PeyHunter/cv/releases) with `cv.html` and `cv.pdf` attached.

```
cv.yml ──► cv.typ (Typst) ──► dist/cv.html  ─┬─► GitHub Release (v1.2.0)
             + style.css      dist/cv.pdf   ─┤
             + fonts/                         └─► ghcr.io/peyhunter/cv:v1.2.0 ──► k3s-gitops ──► Argo CD ──► cv.peytonhunter.com
```

| File | What it is |
|---|---|
| `cv.yml` | The content. This is the only file you edit to update the CV. |
| `cv.typ` | The layout. Builds the web page or the PDF from `cv.yml`. |
| `style.css` | Styles for the web page (inlined into `cv.html`). |
| `fonts/` | Bricolage Grotesque, Plus Jakarta Sans, Reddit Mono (OFL), so the PDF looks the same everywhere. |
| `build.sh` | Builds `dist/`. CI runs the same script. |
| `Dockerfile`, `nginx.conf` | A tiny nginx image that serves `dist/`. |
| `deploy/k3s-gitops/` | The cluster files, to copy into the k3s-gitops repo once. |

## Update the CV

```sh
# 1. edit cv.yml, then preview
./build.sh && xdg-open dist/cv.html && xdg-open dist/cv.pdf

# 2. commit, then release a new version
git commit -am "CV: add <what changed>"
git push
git tag v1.1.0 && git push origin v1.1.0
```

The tag starts the workflow, which publishes the release, pushes the image and bumps `cv/kustomization.yaml` in k3s-gitops. Argo CD then rolls it out.

Pushes to `main` without a tag only build and check. The files are kept as a workflow artifact, and nothing goes live.

Needs [Typst](https://github.com/typst/typst/releases) 0.15.1. HTML export is still an experimental Typst feature, so `build.sh` turns it on with `TYPST_FEATURES=html`.
