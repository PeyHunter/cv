// One source, two outputs:
//   typst compile --features html --font-path fonts cv.typ dist/index.html
//   typst compile --font-path fonts cv.typ dist/cv.pdf
// The content lives in cv.yml. This file is only layout.

#let cv = yaml("cv.yml")
#let version = sys.inputs.at("version", default: "dev")
#let source-url = "https://github.com/PeyHunter/cv"

// ---------- small helpers shared by both outputs ----------

#let months = ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

// "2024-08" -> "Aug 2024", "2027-01 (expected)" -> "Jan 2027 (expected)"
#let fmt-date(d) = {
  let d = str(d)
  let m = d.match(regex("^(\d{4})-(\d{2})(.*)$"))
  if m == none { return if d == "" { d } else { upper(d.first()) + d.slice(d.first().len()) } }
  let (year, month, rest) = m.captures
  months.at(int(month) - 1) + " " + year + rest
}

#let when(e) = if str(e.start) == str(e.end) { fmt-date(e.start) } else { fmt-date(e.start) + " – " + fmt-date(e.end) }
#let at-place(e) = (e.org, e.at("place", default: none)).filter(x => x not in (none, "")).join(" · ")

// Sections made of dated entries, in the order they appear: (cv.yml key, heading).
// Projects and skills come after these.
#let entry-sections = (
  ("experience", "Experience"),
  ("education", "Education"),
  ("courses", "Courses"),
  ("design", "Graphic design"),
).filter(((key, _)) => cv.at(key, default: ()).len() > 0)

// Contact links as (label, href) pairs, skipping empty ones.
#let contact-links = {
  let c = cv.contact
  (
    (c.email, "mailto:" + c.email),
    (c.phone, "tel:" + c.phone.replace(" ", "")),
    (c.website, "https://" + c.website),
    ("github.com/" + c.github, "https://github.com/" + c.github),
    if c.at("linkedin", default: "") != "" {
      ("linkedin.com/in/" + c.linkedin, "https://www.linkedin.com/in/" + c.linkedin)
    },
  ).filter(x => x != none)
}

// ===========================================================
// HTML: the page served at cv.peytonhunter.com
// ===========================================================

#let el(tag, body, ..attrs) = html.elem(tag, attrs: attrs.named(), body)

#let html-entry(e) = el("article", class: "entry", {
  el("p", class: "when", when(e))
  el("div", {
    el("h3", e.title)
    el("p", class: "org", at-place(e))
    if e.at("points", default: ()).len() > 0 {
      el("ul", e.points.map(p => el("li", p)).join())
    }
  })
})

#let html-section(id, title, body) = el("section", id: id, {
  el("h2", title)
  body
})

#let html-page() = el("html", lang: "en", {
  el("head", {
    html.elem("meta", attrs: (charset: "utf-8"))
    html.elem("meta", attrs: (name: "viewport", content: "width=device-width, initial-scale=1"))
    el("title", cv.name + " · CV")
    // Same plain black box as peytonhunter.com, inlined so cv.html works on its own
    html.elem("link", attrs: (rel: "icon", type: "image/svg+xml", href: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' fill='%23000'/%3E%3C/svg%3E"))
    html.elem("meta", attrs: (name: "description", content: cv.name + ", " + cv.role + ". " + cv.status + "."))
    html.elem("link", attrs: (rel: "preconnect", href: "https://fonts.googleapis.com"))
    html.elem("link", attrs: (rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: ""))
    html.elem("link", attrs: (rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,200..800&family=Plus+Jakarta+Sans:ital,wght@0,300..800;1,300..800&family=Reddit+Mono:wght@300..700&display=swap"))
    el("style", read("style.css"))
  })
  el("body", el("main", class: "cv", {
    el("header", {
      el("p", class: "status", cv.status)
      el("h1", cv.name)
      el("p", class: "role", cv.role + " · " + cv.location)
      el("ul", class: "contact", contact-links.map(((label, href)) =>
        el("li", el("a", href: href, label))).join())
      el("a", class: "download", href: "cv.pdf", download: "", "Download PDF")
    })

    html-section("about", "About", el("p", class: "summary", cv.summary))

    for (key, title) in entry-sections {
      html-section(key, title, cv.at(key).map(html-entry).join())
    }

    if cv.projects.len() > 0 {
      html-section("projects", "Projects", cv.projects.map(p => el("article", class: "project", {
        el("div", class: "project-head", {
          el("h3", el("a", href: p.link, p.name))
          el("span", class: "when", str(p.year))
        })
        el("p", p.text)
        el("ul", class: "tags", p.tech.map(t => el("li", t)).join())
      })).join())
    }

    html-section("skills", "Skills", el("dl", class: "skills", cv.skills.map(s => {
      el("dt", s.group)
      el("dd", s.items.join(", "))
    }).join()))

    if cv.languages.len() > 0 {
      html-section("languages", "Languages", el("dl", class: "skills", cv.languages.map(l => {
        el("dt", l.name)
        el("dd", l.level)
      }).join()))
    }

    el("footer", {
      [Built with Typst from ]
      el("a", href: source-url, "PeyHunter/cv")
      [ · ]
      el("a", href: source-url + "/releases/tag/" + version, version)
    })
  }))
})

// ===========================================================
// PDF: print-friendly, one A4 page
// ===========================================================

#let ink = rgb("#111111")
#let muted = rgb("#5b5b5b")
#let accent = rgb("#2563eb")
#let heading-font = "Bricolage Grotesque 96pt"
#let mono-font = "Reddit Mono"

#let pdf-section(title, body) = {
  // sticky: never leave a heading alone at the bottom of a page
  block(sticky: true, above: 12pt, below: 6pt, {
    text(font: heading-font, weight: 700, size: 12pt, title)
    v(-4pt)
    line(length: 100%, stroke: 0.5pt + muted.lighten(50%))
  })
  body
}

#let pdf-entry(e) = grid(
  columns: (26mm, 1fr),
  column-gutter: 4mm,
  text(size: 8pt, fill: muted, font: mono-font, when(e)),
  {
    text(weight: 700, e.title)
    linebreak()
    text(fill: muted, at-place(e))
    if e.at("points", default: ()).len() > 0 {
      v(2pt)
      list(..e.points)
    }
  },
)

#let pdf-page() = {
  set document(title: cv.name + " · CV", author: cv.name)
  set page(paper: "a4", margin: (x: 16mm, y: 14mm))
  set text(font: "Plus Jakarta Sans", size: 9pt, fill: ink, lang: "en")
  set par(leading: 0.55em, spacing: 0.8em)
  set list(indent: 0pt, body-indent: 5pt, spacing: 0.45em, marker: text(fill: accent, "–"))
  show link: set text(fill: ink)
  // Every entry is a grid: keep each one on a single page
  show grid: it => block(breakable: false, it)

  // Header
  text(font: mono-font, size: 8pt, fill: accent, upper(cv.status))
  v(-2pt)
  text(font: heading-font, weight: 800, size: 30pt, cv.name)
  v(-8pt)
  text(size: 11pt, fill: muted, cv.role + " · " + cv.location)
  v(1pt)
  text(size: 8.5pt, contact-links.map(((label, href)) => link(href, label)).join(h(4pt) + text(fill: muted, "·") + h(4pt)))

  pdf-section("About", par(cv.summary))

  for (key, title) in entry-sections {
    pdf-section(title, stack(spacing: 7pt, ..cv.at(key).map(pdf-entry)))
  }

  if cv.projects.len() > 0 {
    pdf-section("Projects", stack(spacing: 7pt, ..cv.projects.map(p => grid(
      columns: (26mm, 1fr),
      column-gutter: 4mm,
      text(size: 8pt, fill: muted, font: mono-font, str(p.year)),
      {
        link(p.link, text(weight: 700, p.name))
        h(5pt)
        text(size: 7.5pt, fill: muted, font: mono-font, p.tech.join(" · "))
        linebreak()
        p.text
      },
    ))))
  }

  let pairs(rows) = grid(
    columns: (26mm, 1fr),
    column-gutter: 4mm,
    row-gutter: 5pt,
    ..rows.map(((k, v)) => (text(weight: 700, k), v)).flatten(),
  )

  pdf-section("Skills", pairs(cv.skills.map(s => (s.group, s.items.join(", ")))))

  if cv.languages.len() > 0 {
    pdf-section("Languages", pairs(cv.languages.map(l => (l.name, l.level))))
  }

  place(bottom + right, text(size: 7pt, fill: muted, font: mono-font,
    [Live version: #link("https://cv.peytonhunter.com")[cv.peytonhunter.com] · #version]))
}

#context if target() == "html" { html-page() } else { pdf-page() }
