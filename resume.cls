%%% resume.cls -- single-column resume class built for machine readability
%%%
%%% Engine:   pdfTeX, pdflatex format, ONE pass. No .aux/.out round trip.
%%% Packages: article, inputenc, fontenc, helvet, geometry, xcolor,
%%%           microtype, hyperref. Nothing else -- see Dockerfile.
%%%
%%% Design rules. An Applicant Tracking System never sees the page you look
%%% at, it sees the PDF's text layer. Do not break these:
%%%   * single column; no tabular/multicolumn/minipage in the content flow
%%%   * no icon fonts; contact details are plain, extractable text
%%%   * no hyphenation across line breaks
%%%   * no running header or footer
%%% `make check' proves all of the above against the built PDF, and
%%% `make lint' proves them against the source.
%%%
%%% Content lives in Resume.tex. Everything here is machinery, so that a diff
%%% touching the resume itself stays readable.

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{resume}[2026/11/01 v2.0 ATS-parseable single-column resume]
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[10pt,letterpaper]{article}

%%--------------------------------------------------------------------------
%% 1. Encoding and text-extraction fidelity.
%%    Must come before anything typesets a glyph.
%%--------------------------------------------------------------------------
\RequirePackage[utf8]{inputenc}
\RequirePackage[T1]{fontenc}

% Emit a ToUnicode CMap for every embedded font. Without this, ligatures and
% anything outside plain ASCII extract as garbage -- the previous moderncv
% build turned "efficiently" into "efIciently". Highest-value line in the file.
\input{glyphtounicode}
\pdfgentounicode=1

% glyphtounicode maps ligatures to decomposed ASCII, which is what we want:
% an ATS searching for "efficient" must match. Re-assert it and cover the
% f_i style glyph names some fonts use, so a ligature can never surface as
% U+FB01 regardless of which font ends up embedded.
\pdfglyphtounicode{ff}{0066 0066}
\pdfglyphtounicode{fi}{0066 0069}
\pdfglyphtounicode{fl}{0066 006C}
\pdfglyphtounicode{ffi}{0066 0066 0069}
\pdfglyphtounicode{ffl}{0066 0066 006C}
\pdfglyphtounicode{f_f}{0066 0066}
\pdfglyphtounicode{f_i}{0066 0069}
\pdfglyphtounicode{f_l}{0066 006C}
\pdfglyphtounicode{f_f_i}{0066 0066 0069}
\pdfglyphtounicode{f_f_l}{0066 0066 006C}

%%--------------------------------------------------------------------------
%% 2. Fonts. Helvetica (helvet, set in Nimbus Sans outlines).
%%
%%    Nearly every sans breaks text extraction on the same character, the ffi
%%    ligature: "efficient" comes out as "efIcient" or as U+FB03. Disabling
%%    f-ligatures outright (see \DisableLigatures below) fixes the whole class
%%    at once and frees the font choice.
%%
%%    One extraction property is still worth respecting: the width of the
%%    interword space as encoded in the PDF, since threshold-based text
%%    extractors infer word breaks from it. Measured from the TJ operators:
%%      Latin Modern Sans  -333/-367     Nimbus Sans  -278
%%      Noto Sans          -260          Source Sans Pro  -200
%%    Source Sans Pro's 0.200 em space is narrow enough that Ghostscript merges
%%    every word in the document, so avoid it. Nimbus Sans sits comfortably in
%%    the normal range.
%%
%%    helvet has no `bx' series, only `b'. Asking for bx logs a font-shape
%%    substitution, which tools/ats_check.py treats as a build failure, so the
%%    default bold series is pointed at the one that exists.
%%--------------------------------------------------------------------------
\RequirePackage{helvet}
\renewcommand{\familydefault}{\sfdefault}
\renewcommand{\bfdefault}{b}
\renewcommand{\ttdefault}{pcr}   % never fall back to Type3 bitmaps

%%--------------------------------------------------------------------------
%% 3. Page. No header, no footer, no page number: nothing that could
%%    interleave repeated text into the middle of the extracted stream.
%%--------------------------------------------------------------------------
\RequirePackage[letterpaper,
                top=0.5in, bottom=0.5in, left=0.6in, right=0.6in]{geometry}
\pagestyle{empty}

\RequirePackage{xcolor}
% Dark enough to survive printing and photocopying. The text extractors an ATS
% uses ignore color, so none of this affects parsing.
%   accent  name, section headings and links
%   muted   dates and locations: secondary, still about 7:1 against white
%   hairline  the rule under section headings, purely decorative
\definecolor{accent}{HTML}{1F4E79}
\definecolor{muted}{HTML}{4A5560}
\definecolor{hairline}{HTML}{C5CCD3}

\RequirePackage[protrusion=true,expansion=false]{microtype}

% Disable f-ligatures. An ffi ligature is a single glyph, and in most fonts it
% carries no usable ToUnicode mapping, so "efficient" extracts as "efIcient"
% or as U+FB03 -- either way it will not match a keyword search. Setting the
% words in separate glyphs costs a sliver of typographic polish at 10pt and
% removes the failure mode completely, for every font.
\DisableLigatures[f]{encoding = T1, family = *}

%%--------------------------------------------------------------------------
%% 4. Links. bookmarks=false is what keeps this a single-pass build: no .out
%%    file, so no "Rerun to get outlines right".
%%
%%    The document metadata itself -- pdftitle, pdfauthor, pdfkeywords -- is
%%    content, so Resume.tex sets it with \hypersetup.
%%--------------------------------------------------------------------------
\RequirePackage[
  bookmarks=false,
  colorlinks=true,
  allcolors=accent,
  breaklinks=true,
  pdfpagemode=UseNone,
  pdflang={en-US}
]{hyperref}

%%--------------------------------------------------------------------------
%% 5. Paragraph shape: ragged right, hyphenation off entirely.
%%    A word split as "Kuber-\nnetes" does not match the keyword
%%    "Kubernetes" in any ATS. Three independent mechanisms, so a stray
%%    package or \selectlanguage cannot quietly re-enable it:
%%      hyphenpenalty/exhyphenpenalty  make any hyphen break infinitely bad
%%      lefthyphenmin/righthyphenmin   make every word too short to hyphenate
%%      pretolerance                   makes TeX accept the no-hyphenation pass
%%    exhyphenpenalty is the one people forget: it stops "dual-stack" breaking
%%    after the hyphen you typed yourself, which is indistinguishable from
%%    real hyphenation once the text is extracted.
%%    Overfull boxes are avoided by giving \rightskip infinite stretch, never
%%    by allowing hyphenation.
%%
%%    \rightskip MUST be "plus 1fil", not a finite stretch. With a finite
%%    value, a line needing more slack than that has nowhere to put it, so
%%    TeX shrinks the interword spaces instead -- and once they shrink past a
%%    text extractor's threshold the words fuse together in the text layer:
%%    "Workingacrossarangeofoperatingsystems". Greenhouse lists exactly this
%%    class of damage as a parse failure. Infinite stretch absorbs any amount
%%    of slack, so interword spaces always keep their natural width.
%%--------------------------------------------------------------------------
\makeatletter
\newcommand{\resume@nohyphen}{%
  \hyphenpenalty=10000
  \exhyphenpenalty=10000
  \lefthyphenmin=62
  \righthyphenmin=62
}
% \@rightskip as well as \rightskip: LaTeX's \list restores \rightskip from
% \@rightskip when it starts, so setting only \rightskip leaves every bullet
% justified -- which is both uglier and risky, since justification shrinks
% interword spaces on tight lines and that is what fuses words together in
% the extracted text layer.
\newcommand{\resumeRaggedRight}{%
  \resume@nohyphen
  \@rightskip=\z@ \@plus 1fil
  \rightskip=\@rightskip
  \parfillskip=\z@ \@plus 1fil
}
\makeatother

\setlength{\parindent}{0pt}
\setlength{\parskip}{0pt}

% Default leading. If a future edit pushes to three pages, `make check' fails:
% trim content rather than tightening this, and never reintroduce negative
% \vspace hacks.

\AtBeginDocument{\resumeRaggedRight}

\clubpenalty=10000
\widowpenalty=10000
% Loose lines are the deliberate price of no hyphenation, so do not report
% them. Overfull boxes are NOT silenced: \hfuzz is untouched and `make check'
% fails the build on any "Overfull \hbox" in the log.
\hbadness=10000
\vbadness=10000

%%--------------------------------------------------------------------------
%% 6. Element fonts
%%--------------------------------------------------------------------------
\newcommand{\resumeNameFont}{\bfseries\fontsize{22}{26}\selectfont}
\newcommand{\resumeContactFont}{\fontsize{9.5}{12}\selectfont}
\newcommand{\resumeSectionFont}{\bfseries\fontsize{11.5}{14}\selectfont}

%%--------------------------------------------------------------------------
%% 7. Structure. Everything below is single column. The only boxes used are
%%    \mbox and \raisebox; there is no tabular, tabbing, minipage or
%%    multicolumn anywhere, so the PDF content stream is strictly linear.
%%--------------------------------------------------------------------------
\makeatletter

% -- page breaking ----------------------------------------------------------
%    TeX rates a short page with no stretch as maximally bad, whatever the break
%    penalty. \raggedbottom does not help: its stretch is added by the output
%    routine, after the break is chosen. The only stretch the page builder saw was
%    the glue inside \resume@needspace, which made the start of an entry the only
%    acceptable break within roughly 220pt, so a long entry jumped to the next
%    page and left a large gap.
%
%    Infinite stretch in \topskip makes every break equally good, so penalties
%    decide: TeX takes the last -51 that fits, whole bullets stay together, and
%    the page fills. The fill below is a higher order of infinity, so on the
%    finished page it takes all the slack and nothing moves.
\AtBeginDocument{\setlength{\topskip}{10\p@ \@plus 1fil}}
\def\@textbottom{\vskip\z@\@plus 1fill}

% -- one line, #1 flush left, #2 flush right, without a table ---------------
%    Zeroing \parfillskip and \rightskip leaves \hfill as the only infinite
%    glue on the line, so it takes all the slack and #2 lands hard right.
%    This is the classic bug in hand-rolled resume templates: with LaTeX's
%    default \parfillskip=0pt plus 1fil, \hfill and \parfillskip are the same
%    order of infinity and split the slack evenly, leaving the date stranded
%    mid-line. Deliberately not \hbox to \linewidth, which overflows into the
%    margin the moment a role title grows.
%    Extracted stream order is #1 then #2, i.e. exactly the reading order.
\newcommand{\resume@line}[2]{%
  \par
  \begingroup
    \resume@nohyphen
    \rightskip=\z@
    \parfillskip=\z@
    #1\hfill#2\par
  \endgroup
}

% -- needspace, without needspace.sty --------------------------------------
%    The penalty matches LaTeX's -51 between list items, so the page builder
%    treats the start of an entry and the gap between two bullets alike. See the
%    page-breaking note below for why that comparison can happen at all.
\newcommand{\resume@needspace}[1]{%
  \begingroup
    \setlength{\dimen@}{#1}%
    \vskip\z@\@plus\dimen@
    \penalty-51
    \vskip\z@\@plus-\dimen@
    \vskip\dimen@
    \penalty9999
    \vskip-\dimen@
    \vskip\z@skip
  \endgroup
}

% -- section heading, without titlesec -------------------------------------
%    The first entry under a heading must not offer a page break, or the heading
%    could be stranded at the bottom of a page. See \resumeEntry.
\newif\ifresume@afterheading
\newcommand{\resumeSection}[1]{%
  \par
  \addvspace{9\p@}%
  \resume@needspace{4\baselineskip}%
  {\color{accent}\resumeSectionFont #1}%
  \par\nobreak
  % Without \nointerlineskip the rule is pushed a full \baselineskip below the
  % heading, which reads as a stray gap rather than an underline.
  \nointerlineskip
  \vskip 2\p@
  \noindent{\color{hairline}\rule{\linewidth}{0.5\p@}}%
  \par\nobreak
  \vskip 3\p@
  \nobreak
  \global\resume@afterheadingtrue
}

% -- name and contact block, immediately under the name --------------------
\newcommand{\resumeSep}{\ \textbar\ }
\newcommand{\resumeHeader}[2]{%
  \begingroup
    \parindent=\z@ \parskip=\z@
    \resume@nohyphen
    {\color{accent}\resumeNameFont #1\par}%
    \vskip 2\p@
    {\resumeContactFont #2\par}%
  \endgroup
}

% -- an experience / education entry ---------------------------------------
%    #1 role  #2 organisation  #3 location  #4 dates
%    Renders as
%        Senior Engineer                                  2009 - 2014
%        Example Corp | Iowa City, IA
%    Extracted stream: role, dates, organisation, location. Linear, and each
%    date stays next to its own role rather than in a separate column.
\newcommand{\resumeEntry}[4]{%
  \par
  \addvspace{5\p@}%
  \ifresume@afterheading\else\resume@needspace{4\baselineskip}\fi
  \global\resume@afterheadingfalse
  % Each side in its own group: \resume@line does not scope its arguments, so
  % an unbraced \bfseries would carry across the \hfill into the dates.
  \resume@line{{\bfseries #1}}{{\color{muted}\mbox{#4}}}%
  #2{\color{muted}\resumeSep #3}\par
  \nobreak
  \vskip 2\p@
  \nobreak
}

% -- bullets, two levels, without enumitem ---------------------------------
%    Level 1 is \textbullet -> U+2022, the one bullet character every parser
%    recognises as a list marker. Level 2 is \textendash -> U+2013.
%    Both are asserted by tools/ats_check.py's character allowlist.
\newcommand{\resume@listsetup}{%
  \resumeRaggedRight
  % No break before the first bullet, so an entry's heading stays with it.
  \@beginparpenalty=\@M
  \setlength{\partopsep}{\z@}%
  \setlength{\parsep}{\z@}%
  \setlength{\itemindent}{\z@}%
  \setlength{\listparindent}{\z@}%
  \setlength{\rightmargin}{\z@}%
}

\newenvironment{resumeItems}
  {\begin{list}{\textbullet}{%
     \resume@listsetup
     \setlength{\topsep}{1.2\p@}%
     \setlength{\itemsep}{0.8\p@}%
     \setlength{\leftmargin}{1.3em}%
     \setlength{\labelwidth}{0.85em}%
     \setlength{\labelsep}{0.45em}%
   }}
  {\end{list}}

\newenvironment{resumeSubItems}
  {\begin{list}{\textendash}{%
     \resume@listsetup
     \setlength{\topsep}{1\p@}%
     \setlength{\itemsep}{0.5\p@}%
     \setlength{\leftmargin}{1.2em}%
     \setlength{\labelwidth}{0.75em}%
     \setlength{\labelsep}{0.45em}%
   }}
  {\end{list}}

% -- bold run-in lead-in, replaces moderncv's two-column \cvitem -----------
\newcommand{\resumeLead}[1]{\par\addvspace{2\p@}\textbf{#1:}\space}

\makeatother

\endinput
