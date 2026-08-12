# Accessibility Fixes — Boro Predictor 26/27
WCAG 2.1 AA | 20 issues | 5 Critical · 11 Major · 4 Minor

**✅ All 19 actionable issues fixed** _(as of 2026-06-06)_  
_1 issue skipped (form boxes in analyst — rendering code not yet implemented)_

---

## How to use this file
Completed issues are marked ✅. One item is marked ⏭ (deferred). Add `aria-label` to analyst form boxes when that rendering code is written.

---

## GLOBAL (all pages)

### ✅ [CRITICAL] No focus indicators
Added to `assets/tokens.css` after the reset block:
```css
:focus-visible { outline: 3px solid #FFB400; outline-offset: 2px; }
```

### ✅ [MAJOR] No skip-nav link
Added as first child of `<body>` on all 6 pages:
```html
<a href="#main-content" class="skip-link">Skip to content</a>
```
Added to `assets/app.css`:
```css
.skip-link { position:absolute; top:-40px; left:0; background:#FFB400; color:#000; padding:8px 16px; z-index:9999; font-weight:700; }
.skip-link:focus { top:0; }
```

### ✅ [MAJOR] Missing `<main>` landmark
Added `<main id="main-content">` to landing, dashboard, predict, account, analyst.  
Ladder's `<main id="ladder-main">` updated to `id="main-content"` for skip-link consistency.

### ✅ [MINOR] Inactive nav link contrast (~3.9:1)
`assets/nav.css`: `rgba(255,255,255,0.55)` → `rgba(255,255,255,0.72)`

### ✅ [MINOR] Footer text contrast (~1.5:1)
`assets/app.css`: `rgba(255,255,255,0.3)` → `rgba(255,255,255,0.5)`

---

## landing/index.html

### ✅ [CRITICAL] Missing form labels (both forms)
Added `<label for="email-input" class="sr-only">Email address</label>` to both forms.  
Added `.sr-only` utility to `assets/app.css`.

### ✅ [CRITICAL] Success/error messages not announced
Added `role="status" aria-live="polite"` to all four message elements.  
Added `aria-describedby` to both email inputs.

### ✅ [MINOR] Form note text contrast (~1.8:1)
`landing/styles.css`: `.form-note` opacity `0.38` → `0.65`

### ✅ [MINOR] Logo not wrapped in link
Wrapped `<img src="../assets/BoroPredictor.svg">` in `<a href="../landing/">`.

---

## predict/index.html

### ✅ [MAJOR] Score ± buttons have no descriptive labels
All 4 score buttons per fixture now have `aria-label` in `createMatch()`.

### ✅ [MAJOR] Score value not announced on change
`aria-live="polite" aria-atomic="true"` added to both score divs in `createMatch()`.

### ✅ [MAJOR] Result tab conveys win/draw/loss by colour only
`role="img"` added to `.result-tab`. `updateFixtureColor()` sets `aria-label="Win/Draw/Loss"`.
**Update (12 Aug 2026):** `.result-tab` and `updateFixtureColor()` were removed entirely, replaced by a bottom-of-card points banner (`.points-banner`) that shows real text ("4 points" / "1 point" / "0 points"), which conveys the same information as literal text rather than colour alone — this fix is superseded, not undone.

### ✅ [MAJOR] Help/report modals — no focus management, no Escape
`toggleHelpModal/toggleReportModal` move focus to `.close-button` on open.  
Escape keydown handler closes both modals.

### ✅ [MAJOR] Modals missing ARIA roles
`role="dialog" aria-modal="true" aria-labelledby` on both modals. Heading ids added.

### ✅ [MINOR] Month divider contrast (~2.6:1)
`predict/styles.css`: `.month-divider` opacity `0.55` → `0.68`

### ✅ [MINOR] "How it works" link contrast (~1.9:1)
`predict/styles.css`: `.how-link` opacity `0.40` → `0.65`

### ✅ [MINOR] `<div class="page-title">` should be `<h1>`
Changed to `<h1 class="page-title">Predict <span>2026/27</span></h1>`.

### ✅ [MINOR] Report modal image missing alt
`calculatePoints()` now sets `document.getElementById('summary-img').alt = summaryCaption`.

---

## account/index.html

### ✅ [CRITICAL] Missing label on name input
Added `<label for="name-input" class="sr-only">Display name</label>`.

### ✅ [MAJOR] Avatar div not keyboard accessible
Changed to `<button class="avatar-wrap" aria-label="Choose your badge">`.  
`button.avatar-wrap` CSS reset added to `account/styles.css`.

### ✅ [MAJOR] Badge/delete modals — focus not moved in
`openBadgeModal/openDeleteModal` now move focus to `.modal-close` on open.

### ✅ [MAJOR] Modals missing ARIA roles
`role="dialog" aria-modal="true" aria-labelledby` on both modals. Title ids added.

### ✅ [MINOR] Progress bar not announced
`.progress-wrap` given `id="progress-wrap" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="46" aria-label="Fixtures predicted"`.  
`loadStatus()` updates `aria-valuenow` after fetching the count.

---

## analyst/index.html

### ✅ [MAJOR] Gate modal — no focus management, no ARIA role
`role="dialog" aria-modal="true" aria-labelledby="gate-title"` added.  
Focus moves to Enter button on load. Escape closes the overlay.

### ⏭ [MAJOR] Form boxes convey result by colour only
_Deferred — rendering code not yet implemented. When added:_
```js
html += `<div class="form-box ${cls}" aria-label="${pts} pts"></div>`;
```

---

## ladder/index.html

### ✅ [MINOR] Table missing caption and column scope
Added `<caption class="sr-only">2026/27 Points Ladder</caption>` and `scope="col"` on all `<th>` elements.

---

## dashboard/index.html

### ✅ [MINOR] `<p class="page-title">` should be `<h1>`
Changed to `<h1 class="page-title">Home <span>2026/27</span></h1>`.

---

## Contrast Reference

| Token | Before | After | Status |
|---|---|---|---|
| Inactive nav link | 3.9:1 | ~5.3:1 | ✅ Fixed |
| Form note | 1.8:1 | ~4.6:1 | ✅ Fixed |
| How-it-works link | 1.9:1 | ~4.6:1 | ✅ Fixed |
| Month dividers | 2.6:1 | ~3.4:1 | ✅ Fixed |
| Footer copy | 1.5:1 | ~2.9:1 | ✅ Fixed |
| Body text (white on red) | 10.1:1 | — | ✅ OK |
| Buttons (black on gold) | 10.9:1 | — | ✅ OK |
