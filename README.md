Michael Merickel's Resume
=========================

My resume, typeset in LaTeX and published as a PDF on each Github release.

The template and tooling come from
[Delta Regeer's resume](https://github.com/digitalresistor/resume). The content
is my own.


Layout
------

`resume.cls` holds the template and the reasoning behind every constraint it
enforces. `Resume.tex` holds only the content, so a diff that changes the resume
stays readable. `tools/` holds the checks.


Building it
-----------

    make                  build Resume.pdf with a local pdflatex
    make lint             source-level checks, no build needed
    make check            build, then validate the PDF (Ghostscript only)
    make check-container  full validation in the CI image, both extractors

`make check-container` is the one that matches CI exactly.

`pre-commit install` wires the source lint to commits, and the full build plus
validation to pushes. The push hook needs a local `pdflatex`. Hooks are a
convenience, not a gate. CI is authoritative.

`tools/ats_check.py` asserts specifics of the content: the contact details, the
order of sections and roles, and a list of keywords. Update its lists when the
resume changes shape.


Why it is built the way it is
-----------------------------

An Applicant Tracking System never sees the rendered page. It reads the PDF's
*text layer*, and common LaTeX resume templates break that layer in ways that
look fine on the page. So there are rules, and `make lint` / `make check` enforce
them rather than trusting anyone to remember them:

* **Single column.** No `tabular`, `multicolumn` or `minipage` in the content
  flow. Right-aligned dates use `\hfill` inside an ordinary paragraph.
* **No icon fonts.** Contact details are plain, extractable text.
* **`\input{glyphtounicode}` + `\pdfgentounicode=1`.** The single
  highest-value line in `resume.cls`.
* **No hyphenation.** `Kuber-\nnetes` does not match a search for `Kubernetes`.
* **`\rightskip` must be `plus 1fil`.** Given only a finite stretch, TeX
  shrinks interword spaces instead, and past a certain point extractors fuse
  the words together: `Workingacrossarangeofoperatingsystems`.
* **No running header or footer**, so nothing can repeat mid-document.
* **Two pages.** `make check` fails at three.

The font is Helvetica, via `helvet`. Nearly every sans breaks extraction on the
same character, the **ffi** ligature: `efficient` comes out as `efIcient` or as
U+FB03. Disabling f-ligatures kills the whole class at once, so the font can be
chosen on looks.

One font property still matters. Text extractors infer word breaks from the width
of the interword space as encoded in the PDF, and those widths vary:

    Latin Modern Sans  -333/-367     Nimbus Sans  -278
    Noto Sans          -260          Source Sans Pro  -200

Source Sans Pro's 0.200 em space is narrow enough that Ghostscript merges every
word in the document, so avoid it. Nimbus Sans sits in the normal range.

`Dockerfile` names every package explicitly and uses `--no-install-recommends`, so
the build cannot silently depend on something apt decided to add.
