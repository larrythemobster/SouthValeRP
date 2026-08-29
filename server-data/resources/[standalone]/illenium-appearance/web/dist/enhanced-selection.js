(() => {
  "use strict";

  const RESOURCE = typeof GetParentResourceName === "function"
    ? GetParentResourceName()
    : "illenium-appearance";

  const CATEGORY_MAP = new Map([
    ["Jackets", { kind: "component", id: 11, label: "Jackets", short: "JKT" }],
    ["Shirt", { kind: "component", id: 8, label: "Shirts", short: "SHR" }],
    ["Body armor", { kind: "component", id: 9, label: "Vests", short: "VST" }],
    ["Hands", { kind: "component", id: 3, label: "Arms", short: "ARM" }],
    ["Legs", { kind: "component", id: 4, label: "Legs", short: "LEG" }],
    ["Shoes", { kind: "component", id: 6, label: "Shoes", short: "SHO" }],
    ["Mask", { kind: "component", id: 1, label: "Masks", short: "MSK" }],
    ["Bags and parachute", { kind: "component", id: 5, label: "Bags", short: "BAG" }],
    ["Scarf and chains", { kind: "component", id: 7, label: "Chains", short: "CHN" }],
    ["Decals", { kind: "component", id: 10, label: "Decals", short: "DCL" }],
    ["Head", { kind: "component", id: 0, label: "Head", short: "HED" }],
    ["Hats and helmets", { kind: "prop", id: 0, label: "Hats", short: "HAT" }],
    ["Glasses", { kind: "prop", id: 1, label: "Glasses", short: "GLS" }],
    ["Ear", { kind: "prop", id: 2, label: "Ears", short: "EAR" }],
    ["Watches", { kind: "prop", id: 6, label: "Watches", short: "WTC" }],
    ["Bracelets", { kind: "prop", id: 7, label: "Bracelets", short: "BRC" }]
  ]);

  const CLOTHING_ORDER = [
    "Jackets", "Shirt", "Body armor", "Hands", "Legs", "Shoes", "Mask",
    "Bags and parachute", "Scarf and chains", "Decals", "Head"
  ];

  const stateByCard = new WeakMap();
  const cardsByTitle = new Map();
  let scanQueued = false;
  let browserMount = null;
  let browserRoot = null;
  let selectedTitle = "Jackets";
  let pageStart = 0;
  const PAGE_SIZE = 12;
  let browserRequestToken = 0;
  let hoverRestoreToken = 0;
  let currentPage = null;
  let pendingSelection = null;

  function post(name, payload) {
    return fetch(`https://${RESOURCE}/${name}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(payload || {})
    }).then((response) => response.json());
  }

  function injectStyles() {
    if (document.getElementById("southvale-clean-clothing-style")) return;

    const style = document.createElement("style");
    style.id = "southvale-clean-clothing-style";
    style.textContent = `
      :root {
        --sv-bg: 10, 7, 13;
        --sv-panel: 17, 10, 21;
        --sv-panel-2: 25, 14, 30;
        --sv-line: 255, 255, 255;
        --sv-text: 248, 247, 250;
        --sv-muted: 168, 155, 176;
        --sv-accent: 229, 16, 62;
        --sv-accent-soft: 255, 58, 111;
        --sv-gold: 245, 180, 42;
      }

      .sv-appearance-panel {
        position: fixed !important;
        top: 18px !important;
        right: 18px !important;
        left: auto !important;
        width: min(420px, calc(100vw - 36px)) !important;
        max-width: 420px !important;
        height: calc(100vh - 36px) !important;
        padding: 12px !important;
        z-index: 9990 !important;
        overflow-x: hidden !important;
        overflow-y: auto !important;
        border: 1px solid rgba(var(--sv-accent-soft), .25) !important;
        border-radius: 14px !important;
        background:
          radial-gradient(circle at 80% 0%, rgba(var(--sv-accent), .12), transparent 35%),
          linear-gradient(180deg, rgba(var(--sv-panel), .97), rgba(var(--sv-bg), .96)) !important;
        box-shadow: 0 24px 70px rgba(0, 0, 0, .46) !important;
        backdrop-filter: blur(12px) !important;
      }

      .sv-appearance-panel::-webkit-scrollbar { width: 4px !important; }
      .sv-appearance-panel::-webkit-scrollbar-track { background: transparent !important; }
      .sv-appearance-panel::-webkit-scrollbar-thumb {
        background: rgba(var(--sv-accent-soft), .32) !important;
        border-radius: 999px !important;
      }

      .sv-original-clothing-card {
        display: none !important;
      }

      .sv-catalog {
        width: 100%;
        min-height: 590px;
        margin: 0 0 10px;
        overflow: hidden;
        color: rgb(var(--sv-text));
        border: 1px solid rgba(var(--sv-line), .07);
        border-radius: 11px;
        background: rgba(var(--sv-bg), .82);
        box-shadow: 0 12px 28px rgba(0, 0, 0, .2);
        font-family: inherit;
      }

      .sv-catalog * { box-sizing: border-box; }

      .sv-catalog-header {
        padding: 15px 15px 12px;
        border-bottom: 1px solid rgba(var(--sv-line), .075);
        background: linear-gradient(180deg, rgba(var(--sv-accent), .08), rgba(var(--sv-panel), .15));
      }

      .sv-catalog-brand {
        display: flex;
        align-items: baseline;
        justify-content: space-between;
        gap: 12px;
      }

      .sv-catalog-brand strong {
        font-size: 17px;
        font-weight: 900;
        line-height: 1;
        letter-spacing: .18em;
        text-transform: uppercase;
        background: linear-gradient(90deg, rgb(var(--sv-accent-soft)), rgb(var(--sv-gold)));
        -webkit-background-clip: text;
        color: transparent;
      }

      .sv-catalog-brand span {
        color: rgba(var(--sv-muted), .9);
        font-size: 8px;
        font-weight: 800;
        letter-spacing: .18em;
        text-transform: uppercase;
      }

      .sv-catalog-subtitle {
        margin-top: 7px;
        color: rgba(var(--sv-muted), .92);
        font-size: 9px;
        line-height: 1.35;
      }

      .sv-catalog-body {
        display: grid;
        grid-template-columns: 76px minmax(0, 1fr);
        min-height: 515px;
      }

      .sv-category-rail {
        padding: 8px 6px;
        border-right: 1px solid rgba(var(--sv-line), .07);
        background: rgba(var(--sv-panel), .52);
      }

      .sv-category-button {
        width: 100%;
        min-height: 50px;
        margin: 0 0 5px;
        padding: 6px 3px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 4px;
        border: 1px solid transparent;
        border-radius: 7px;
        background: transparent;
        color: rgba(var(--sv-muted), .86);
        cursor: pointer;
        transition: border-color .12s ease, background .12s ease, color .12s ease, transform .12s ease;
      }

      .sv-category-button:hover {
        color: rgb(var(--sv-text));
        background: rgba(var(--sv-line), .035);
      }

      .sv-category-button.is-active {
        color: rgb(var(--sv-gold));
        border-color: rgba(var(--sv-gold), .34);
        background: linear-gradient(135deg, rgba(var(--sv-gold), .11), rgba(var(--sv-accent), .08));
        box-shadow: inset 2px 0 0 rgb(var(--sv-accent-soft));
      }

      .sv-category-short {
        display: grid;
        place-items: center;
        width: 28px;
        height: 21px;
        color: currentColor;
        font-size: 8px;
        font-weight: 950;
        letter-spacing: .08em;
      }

      .sv-category-label {
        max-width: 64px;
        overflow: hidden;
        color: currentColor;
        font-size: 7px;
        font-weight: 800;
        letter-spacing: .045em;
        line-height: 1.15;
        text-align: center;
        text-overflow: ellipsis;
        text-transform: uppercase;
        white-space: nowrap;
      }

      .sv-catalog-content {
        min-width: 0;
        padding: 9px;
        display: flex;
        flex-direction: column;
      }

      .sv-content-title {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 8px;
        margin-bottom: 7px;
      }

      .sv-content-title strong {
        font-size: 11px;
        font-weight: 900;
        letter-spacing: .12em;
        text-transform: uppercase;
      }

      .sv-live-badge {
        display: inline-flex;
        align-items: center;
        gap: 5px;
        padding: 4px 7px;
        border: 1px solid rgba(var(--sv-accent-soft), .22);
        border-radius: 999px;
        color: rgba(var(--sv-accent-soft), .95);
        background: rgba(var(--sv-accent), .07);
        font-size: 7px;
        font-weight: 900;
        letter-spacing: .08em;
        text-transform: uppercase;
      }

      .sv-live-badge::before {
        content: "";
        width: 5px;
        height: 5px;
        border-radius: 50%;
        background: rgb(var(--sv-accent-soft));
        box-shadow: 0 0 8px rgba(var(--sv-accent-soft), .75);
      }

      .sv-steppers {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 6px;
        margin-bottom: 8px;
      }

      .sv-stepper {
        min-width: 0;
        padding: 5px;
        border: 1px solid rgba(var(--sv-line), .075);
        border-radius: 7px;
        background: rgba(var(--sv-panel-2), .58);
      }

      .sv-stepper-label {
        margin: 0 0 4px 2px;
        color: rgba(var(--sv-muted), .9);
        font-size: 7px;
        font-weight: 900;
        letter-spacing: .1em;
        text-transform: uppercase;
      }

      .sv-stepper-control {
        height: 29px;
        display: grid;
        grid-template-columns: 28px 1fr 28px;
        align-items: center;
        border: 1px solid rgba(var(--sv-line), .06);
        border-radius: 5px;
        overflow: hidden;
        background: rgba(var(--sv-bg), .66);
      }

      .sv-stepper-control button {
        height: 100%;
        border: 0;
        background: transparent;
        color: rgba(var(--sv-text), .9);
        font-size: 16px;
        cursor: pointer;
      }

      .sv-stepper-control button:hover {
        color: rgb(var(--sv-accent-soft));
        background: rgba(var(--sv-accent), .08);
      }

      .sv-stepper-value {
        min-width: 0;
        overflow: hidden;
        color: rgb(var(--sv-text));
        font-size: 10px;
        font-weight: 850;
        text-align: center;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .sv-selection-name {
        min-height: 30px;
        margin-bottom: 8px;
        padding: 7px 8px;
        overflow: hidden;
        border-left: 2px solid rgb(var(--sv-accent-soft));
        background: linear-gradient(90deg, rgba(var(--sv-accent), .08), transparent 80%);
        color: rgba(var(--sv-text), .94);
        font-size: 9px;
        line-height: 1.35;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .sv-grid {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 6px;
      }

      .sv-item {
        position: relative;
        min-width: 0;
        aspect-ratio: .98;
        padding: 0;
        overflow: hidden;
        border: 1px solid rgba(var(--sv-line), .08);
        border-radius: 7px;
        background:
          radial-gradient(circle at 50% 30%, rgba(var(--sv-line), .055), transparent 55%),
          rgba(var(--sv-panel-2), .54);
        color: rgb(var(--sv-text));
        cursor: pointer;
        transition: transform .12s ease, border-color .12s ease, background .12s ease, box-shadow .12s ease;
      }

      .sv-item:hover {
        z-index: 2;
        transform: translateY(-1px);
        border-color: rgba(var(--sv-accent-soft), .46);
        background: rgba(var(--sv-accent), .075);
        box-shadow: 0 8px 18px rgba(0, 0, 0, .22);
      }

      .sv-item.is-selected {
        border-color: rgb(var(--sv-accent-soft));
        box-shadow: inset 0 0 0 1px rgba(var(--sv-accent-soft), .25), 0 0 16px rgba(var(--sv-accent), .11);
      }

      .sv-item-image {
        width: 100%;
        height: 70%;
        display: grid;
        place-items: center;
        overflow: hidden;
      }

      .sv-item-image img {
        width: 100%;
        height: 100%;
        display: block;
        object-fit: contain;
      }

      .sv-item-fallback {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 3px;
        color: rgba(var(--sv-muted), .74);
      }

      .sv-item-fallback strong {
        color: rgba(var(--sv-text), .9);
        font-size: 15px;
        font-weight: 950;
        letter-spacing: .07em;
      }

      .sv-item-fallback span {
        font-size: 7px;
        font-weight: 800;
        letter-spacing: .08em;
        text-transform: uppercase;
      }

      .sv-item-meta {
        height: 30%;
        padding: 5px 6px;
        border-top: 1px solid rgba(var(--sv-line), .05);
        background: rgba(var(--sv-bg), .46);
      }

      .sv-item-number {
        display: inline-block;
        margin-right: 4px;
        color: rgb(var(--sv-gold));
        font-size: 8px;
        font-weight: 950;
      }

      .sv-item-label {
        display: block;
        margin-top: 2px;
        overflow: hidden;
        color: rgba(var(--sv-text), .8);
        font-size: 7px;
        line-height: 1.15;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .sv-check {
        position: absolute;
        top: 5px;
        right: 5px;
        width: 15px;
        height: 15px;
        display: grid;
        place-items: center;
        border-radius: 50%;
        background: rgb(var(--sv-accent-soft));
        color: white;
        font-size: 9px;
        font-weight: 950;
        opacity: 0;
        transform: scale(.8);
        transition: opacity .12s ease, transform .12s ease;
      }

      .sv-item.is-selected .sv-check {
        opacity: 1;
        transform: scale(1);
      }

      .sv-catalog-footer {
        margin-top: auto;
        padding-top: 8px;
      }

      .sv-page-row {
        display: grid;
        grid-template-columns: 30px 1fr 30px;
        gap: 6px;
        align-items: center;
        margin-bottom: 7px;
      }

      .sv-page-row button {
        height: 27px;
        border: 1px solid rgba(var(--sv-line), .08);
        border-radius: 5px;
        background: rgba(var(--sv-panel-2), .52);
        color: rgba(var(--sv-text), .9);
        cursor: pointer;
      }

      .sv-page-row button:hover:not(:disabled) {
        border-color: rgba(var(--sv-accent-soft), .42);
        color: rgb(var(--sv-accent-soft));
      }

      .sv-page-row button:disabled {
        opacity: .3;
        cursor: default;
      }

      .sv-page-status {
        overflow: hidden;
        color: rgba(var(--sv-muted), .82);
        font-size: 7px;
        font-weight: 800;
        letter-spacing: .06em;
        text-align: center;
        text-overflow: ellipsis;
        text-transform: uppercase;
        white-space: nowrap;
      }

      .sv-action-row {
        display: grid;
        grid-template-columns: 1fr 2fr;
        gap: 6px;
      }

      .sv-action-row button {
        height: 32px;
        border-radius: 6px;
        font-size: 8px;
        font-weight: 950;
        letter-spacing: .1em;
        text-transform: uppercase;
        cursor: pointer;
      }

      .sv-reset {
        border: 1px solid rgba(var(--sv-line), .11);
        background: rgba(var(--sv-panel-2), .64);
        color: rgba(var(--sv-text), .83);
      }

      .sv-apply {
        border: 1px solid rgba(var(--sv-accent-soft), .65);
        background: linear-gradient(90deg, rgb(var(--sv-accent)), rgb(var(--sv-accent-soft)));
        color: #fff;
        box-shadow: 0 7px 18px rgba(var(--sv-accent), .18);
      }

      .sv-apply:disabled {
        border-color: rgba(var(--sv-line), .08);
        background: rgba(var(--sv-panel-2), .5);
        color: rgba(var(--sv-muted), .52);
        box-shadow: none;
        cursor: default;
      }

      .sv-loading {
        grid-column: 1 / -1;
        min-height: 210px;
        display: grid;
        place-items: center;
        color: rgba(var(--sv-muted), .75);
        font-size: 8px;
        font-weight: 800;
        letter-spacing: .1em;
        text-transform: uppercase;
      }

      @media (max-height: 760px) {
        .sv-appearance-panel { top: 8px !important; right: 8px !important; height: calc(100vh - 16px) !important; }
        .sv-catalog { min-height: 520px; }
        .sv-catalog-body { min-height: 445px; }
        .sv-category-button { min-height: 43px; }
        .sv-item { aspect-ratio: 1.12; }
      }

      @media (max-width: 620px) {
        .sv-appearance-panel {
          top: 6px !important;
          right: 6px !important;
          width: calc(100vw - 12px) !important;
          height: calc(100vh - 12px) !important;
        }
      }
    `;
    document.head.appendChild(style);
  }

  function directText(element) {
    let value = "";
    for (const node of element.childNodes) {
      if (node.nodeType === Node.TEXT_NODE) value += node.textContent || "";
    }
    return value.trim();
  }

  function findTitleElements(title) {
    const matches = [];
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT);
    let node = walker.currentNode;

    while (node) {
      if (directText(node) === title) matches.push(node);
      node = walker.nextNode();
    }
    return matches;
  }

  function findCard(titleElement) {
    let current = titleElement;
    while (current && current !== document.body) {
      if (current.querySelectorAll('input[type="number"]').length === 2) return current;
      current = current.parentElement;
    }
    return null;
  }

  function getInputs(card) {
    const inputs = Array.from(card.querySelectorAll('input[type="number"]'));
    if (inputs.length !== 2) return null;
    return { drawable: inputs[0], texture: inputs[1] };
  }

  function numberValue(input, fallback) {
    const value = Number.parseInt(input.value, 10);
    return Number.isFinite(value) ? value : fallback;
  }

  function readCommitted(title) {
    const card = cardsByTitle.get(title);
    const config = CATEGORY_MAP.get(title);
    if (!card || !config) return null;
    const inputs = getInputs(card);
    if (!inputs) return null;
    return {
      drawable: numberValue(inputs.drawable, config.kind === "prop" ? -1 : 0),
      texture: numberValue(inputs.texture, config.kind === "prop" ? -1 : 0)
    };
  }

  function payloadFor(title, values) {
    const config = CATEGORY_MAP.get(title);
    if (!config || !values) return null;
    return {
      kind: config.kind,
      id: config.id,
      drawable: values.drawable,
      texture: values.texture
    };
  }

  function lowestCommonAncestor(nodes) {
    if (!nodes.length) return null;
    let current = nodes[0];
    while (current && current !== document.body) {
      if (nodes.every((node) => current.contains(node))) return current;
      current = current.parentElement;
    }
    return null;
  }

  function detectPanel(fromNode) {
    let current = fromNode;
    let best = null;
    while (current && current !== document.body) {
      const rect = current.getBoundingClientRect();
      const style = window.getComputedStyle(current);
      const scrollable = style.overflowY === "auto" || style.overflowY === "scroll" || current.scrollHeight > current.clientHeight + 20;
      const panelSized = rect.width > 240 && rect.width < 520 && rect.height > window.innerHeight * 0.55;
      if (panelSized && (scrollable || rect.height > window.innerHeight * 0.8)) {
        best = current;
      }
      current = current.parentElement;
    }
    if (best) best.classList.add("sv-appearance-panel");
    return best;
  }

  function nativeSetValue(input, value) {
    const descriptor = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value");
    if (descriptor && descriptor.set) descriptor.set.call(input, String(value));
    else input.value = String(value);
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }

  function restoreSelection(title, values) {
    const payload = payloadFor(title, values);
    if (!payload) return Promise.resolve();
    return post("appearance_restore_clothing", payload).catch(() => {});
  }

  function previewSelection(title, values) {
    const payload = payloadFor(title, values);
    if (!payload) return Promise.resolve(null);
    return post("appearance_preview_clothing", payload).catch(() => null);
  }

  function getAvailableTitles() {
    return CLOTHING_ORDER.filter((title) => cardsByTitle.has(title));
  }

  function selectionEquals(a, b) {
    return Boolean(a && b && a.drawable === b.drawable && a.texture === b.texture);
  }

  function setSelectedTitle(title) {
    if (!cardsByTitle.has(title)) return;

    const previousCommitted = readCommitted(selectedTitle);
    if (previousCommitted) restoreSelection(selectedTitle, previousCommitted);

    selectedTitle = title;
    const committed = readCommitted(title);
    pendingSelection = committed ? { ...committed } : null;
    pageStart = committed ? Math.max(0, Math.floor(Math.max(0, committed.drawable) / PAGE_SIZE) * PAGE_SIZE) : 0;
    loadAndRender();
  }

  function buildShell() {
    const root = document.createElement("section");
    root.className = "sv-catalog";
    root.innerHTML = `
      <header class="sv-catalog-header">
        <div class="sv-catalog-brand">
          <strong>Southvale</strong>
          <span>Clothing</span>
        </div>
        <div class="sv-catalog-subtitle">Browse first. Hover any item to preview it on your character, then apply only what you want.</div>
      </header>
      <div class="sv-catalog-body">
        <nav class="sv-category-rail" data-sv-categories></nav>
        <main class="sv-catalog-content">
          <div class="sv-content-title">
            <strong data-sv-title>Clothing</strong>
            <span class="sv-live-badge">Live preview</span>
          </div>
          <div class="sv-steppers">
            <div class="sv-stepper">
              <div class="sv-stepper-label">Style</div>
              <div class="sv-stepper-control">
                <button type="button" data-sv-step="drawable:-1" aria-label="Previous style">‹</button>
                <div class="sv-stepper-value" data-sv-drawable>0</div>
                <button type="button" data-sv-step="drawable:1" aria-label="Next style">›</button>
              </div>
            </div>
            <div class="sv-stepper">
              <div class="sv-stepper-label">Variant</div>
              <div class="sv-stepper-control">
                <button type="button" data-sv-step="texture:-1" aria-label="Previous variant">‹</button>
                <div class="sv-stepper-value" data-sv-texture>0</div>
                <button type="button" data-sv-step="texture:1" aria-label="Next variant">›</button>
              </div>
            </div>
          </div>
          <div class="sv-selection-name" data-sv-selection>Choose an item below to preview it.</div>
          <div class="sv-grid" data-sv-grid><div class="sv-loading">Loading catalog…</div></div>
          <footer class="sv-catalog-footer">
            <div class="sv-page-row">
              <button type="button" data-sv-page="-1" aria-label="Previous page">‹</button>
              <div class="sv-page-status" data-sv-page-status>Items</div>
              <button type="button" data-sv-page="1" aria-label="Next page">›</button>
            </div>
            <div class="sv-action-row">
              <button type="button" class="sv-reset" data-sv-reset>Reset</button>
              <button type="button" class="sv-apply" data-sv-apply>Apply item</button>
            </div>
          </footer>
        </main>
      </div>
    `;

    root.addEventListener("click", (event) => {
      const category = event.target.closest("[data-sv-category]");
      if (category) {
        setSelectedTitle(category.dataset.svCategory);
        return;
      }

      const step = event.target.closest("[data-sv-step]");
      if (step) {
        const [axis, rawDirection] = step.dataset.svStep.split(":");
        stepSelection(axis, Number(rawDirection));
        return;
      }

      const item = event.target.closest("[data-sv-item]");
      if (item) {
        const drawable = Number(item.dataset.svItem);
        const pageItem = currentPage && currentPage.items.find((entry) => entry.drawable === drawable);
        if (pageItem) selectCatalogItem(pageItem);
        return;
      }

      const page = event.target.closest("[data-sv-page]");
      if (page) {
        const direction = Number(page.dataset.svPage);
        changePage(direction);
        return;
      }

      if (event.target.closest("[data-sv-reset]")) {
        resetPending();
        return;
      }

      if (event.target.closest("[data-sv-apply]")) {
        applyPending();
      }
    });

    root.addEventListener("mouseover", (event) => {
      const item = event.target.closest("[data-sv-item]");
      if (!item || item.contains(event.relatedTarget)) return;
      const drawable = Number(item.dataset.svItem);
      const pageItem = currentPage && currentPage.items.find((entry) => entry.drawable === drawable);
      if (pageItem) hoverPreview(pageItem);
    });

    root.addEventListener("mouseout", (event) => {
      const item = event.target.closest("[data-sv-item]");
      if (!item || item.contains(event.relatedTarget)) return;
      restoreAfterHover();
    });

    return root;
  }

  function renderCategories() {
    if (!browserRoot) return;
    const rail = browserRoot.querySelector("[data-sv-categories]");
    const titles = getAvailableTitles();
    if (!titles.includes(selectedTitle) && titles.length) selectedTitle = titles[0];

    rail.replaceChildren(...titles.map((title) => {
      const config = CATEGORY_MAP.get(title);
      const button = document.createElement("button");
      button.type = "button";
      button.className = `sv-category-button${title === selectedTitle ? " is-active" : ""}`;
      button.dataset.svCategory = title;
      button.title = config.label;
      button.innerHTML = `<span class="sv-category-short">${config.short}</span><span class="sv-category-label">${config.label}</span>`;
      return button;
    }));
  }

  function renderLoading() {
    if (!browserRoot) return;
    const grid = browserRoot.querySelector("[data-sv-grid]");
    grid.innerHTML = '<div class="sv-loading">Loading catalog…</div>';
  }

  function itemFallback(config, drawable) {
    return `<div class="sv-item-fallback"><strong>${config.short}</strong><span>Style ${drawable}</span></div>`;
  }

  function safeText(value) {
    return String(value ?? "").replace(/[&<>"']/g, (char) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;"
    })[char]);
  }

  function renderPage(page) {
    if (!browserRoot) return;
    currentPage = page;
    renderCategories();

    const config = CATEGORY_MAP.get(selectedTitle);
    const committed = readCommitted(selectedTitle);
    if (!pendingSelection && committed) pendingSelection = { ...committed };

    browserRoot.querySelector("[data-sv-title]").textContent = config.label;
    browserRoot.querySelector("[data-sv-drawable]").textContent = pendingSelection ? pendingSelection.drawable : "—";
    browserRoot.querySelector("[data-sv-texture]").textContent = pendingSelection ? pendingSelection.texture : "—";

    const selectedItem = pendingSelection && page.items.find((item) => item.drawable === pendingSelection.drawable);
    const selectionText = selectedItem
      ? `${selectedItem.label}${selectedItem.collection && selectedItem.collection !== selectedItem.label ? ` · ${selectedItem.collection}` : ""}`
      : pendingSelection
        ? `${config.label} style ${pendingSelection.drawable} · variant ${pendingSelection.texture}`
        : "Choose an item below to preview it.";
    browserRoot.querySelector("[data-sv-selection]").textContent = selectionText;

    const grid = browserRoot.querySelector("[data-sv-grid]");
    const fragment = document.createDocumentFragment();

    for (const item of page.items) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = `sv-item${pendingSelection && item.drawable === pendingSelection.drawable ? " is-selected" : ""}`;
      button.dataset.svItem = String(item.drawable);
      button.title = `${item.label} — hover to preview`;

      const imageContent = item.thumbnail
        ? `<img src="${safeText(item.thumbnail)}" alt="${safeText(item.label)}" draggable="false">`
        : itemFallback(config, item.drawable);

      button.innerHTML = `
        <div class="sv-item-image">${imageContent}</div>
        <div class="sv-item-meta">
          <span class="sv-item-number">${item.drawable}</span>
          <span class="sv-item-label">${safeText(item.label)}</span>
        </div>
        <span class="sv-check">✓</span>
      `;
      fragment.appendChild(button);
    }

    if (!page.items.length) {
      const empty = document.createElement("div");
      empty.className = "sv-loading";
      empty.textContent = "No items available";
      fragment.appendChild(empty);
    }

    grid.replaceChildren(fragment);

    const minShown = page.items.length ? page.items[0].drawable : page.drawableMin;
    const maxShown = page.items.length ? page.items[page.items.length - 1].drawable : page.drawableMax;
    browserRoot.querySelector("[data-sv-page-status]").textContent = `${minShown}–${maxShown} of ${page.drawableMax}`;

    const pageButtons = browserRoot.querySelectorAll("[data-sv-page]");
    pageButtons[0].disabled = page.start <= page.drawableMin;
    pageButtons[1].disabled = page.end >= page.drawableMax;

    const apply = browserRoot.querySelector("[data-sv-apply]");
    apply.disabled = selectionEquals(committed, pendingSelection);
    apply.textContent = apply.disabled ? "Equipped" : "Apply item";
  }

  async function loadAndRender() {
    if (!browserRoot || !cardsByTitle.has(selectedTitle)) return;
    renderLoading();
    renderCategories();

    const token = ++browserRequestToken;
    const config = CATEGORY_MAP.get(selectedTitle);
    const committed = readCommitted(selectedTitle);
    if (!pendingSelection) pendingSelection = committed ? { ...committed } : null;

    const requestedTexture = pendingSelection ? pendingSelection.texture : (config.kind === "prop" ? -1 : 0);
    try {
      const page = await post("appearance_get_clothing_page", {
        kind: config.kind,
        id: config.id,
        start: pageStart,
        count: PAGE_SIZE,
        selectedDrawable: pendingSelection ? pendingSelection.drawable : null,
        selectedTexture: requestedTexture
      });
      if (token !== browserRequestToken || !browserRoot?.isConnected) return;
      pageStart = page.start;
      renderPage(page);
    } catch (_) {
      if (token !== browserRequestToken || !browserRoot?.isConnected) return;
      browserRoot.querySelector("[data-sv-grid]").innerHTML = '<div class="sv-loading">Catalog unavailable</div>';
    }
  }

  async function selectCatalogItem(item) {
    const config = CATEGORY_MAP.get(selectedTitle);
    const texture = pendingSelection && pendingSelection.drawable === item.drawable
      ? pendingSelection.texture
      : (Number.isFinite(item.texture) ? item.texture : (config.kind === "prop" ? -1 : 0));

    const result = await previewSelection(selectedTitle, { drawable: item.drawable, texture });
    if (!result) return;
    pendingSelection = { drawable: result.drawable, texture: result.texture };

    if (result.drawable < pageStart || result.drawable >= pageStart + PAGE_SIZE) {
      pageStart = Math.floor(Math.max(0, result.drawable) / PAGE_SIZE) * PAGE_SIZE;
      loadAndRender();
      return;
    }

    if (currentPage) {
      const index = currentPage.items.findIndex((entry) => entry.drawable === result.drawable);
      if (index >= 0) currentPage.items[index] = { ...currentPage.items[index], ...result };
      renderPage(currentPage);
    }
  }

  async function stepSelection(axis, direction) {
    const config = CATEGORY_MAP.get(selectedTitle);
    const base = pendingSelection || readCommitted(selectedTitle);
    if (!config || !base) return;

    hoverRestoreToken += 1;
    const result = await post("appearance_preview_clothing_step", {
      kind: config.kind,
      id: config.id,
      drawable: base.drawable,
      texture: base.texture,
      axis,
      direction
    }).catch(() => null);

    if (!result) return;
    pendingSelection = { drawable: result.drawable, texture: result.texture };

    if (result.drawable < pageStart || result.drawable >= pageStart + PAGE_SIZE) {
      pageStart = Math.floor(Math.max(0, result.drawable) / PAGE_SIZE) * PAGE_SIZE;
      loadAndRender();
      return;
    }

    if (currentPage) {
      const index = currentPage.items.findIndex((entry) => entry.drawable === result.drawable);
      if (index >= 0) currentPage.items[index] = { ...currentPage.items[index], ...result };
      renderPage(currentPage);
    }
  }

  function hoverPreview(item) {
    const token = ++hoverRestoreToken;
    const config = CATEGORY_MAP.get(selectedTitle);
    const texture = pendingSelection && pendingSelection.drawable === item.drawable
      ? pendingSelection.texture
      : (Number.isFinite(item.texture) ? item.texture : (config.kind === "prop" ? -1 : 0));

    previewSelection(selectedTitle, { drawable: item.drawable, texture }).then((result) => {
      if (!result || token !== hoverRestoreToken || !browserRoot?.isConnected) return;
      const selection = browserRoot.querySelector("[data-sv-selection]");
      selection.textContent = `Preview: ${result.label}`;
    });
  }

  function restoreAfterHover() {
    const token = ++hoverRestoreToken;
    const values = pendingSelection || readCommitted(selectedTitle);
    if (!values) return;

    window.setTimeout(() => {
      if (token !== hoverRestoreToken) return;
      previewSelection(selectedTitle, values).then(() => {
        if (token !== hoverRestoreToken || !currentPage) return;
        renderPage(currentPage);
      });
    }, 20);
  }

  function changePage(direction) {
    if (!currentPage) return;
    const next = pageStart + direction * PAGE_SIZE;
    pageStart = Math.max(currentPage.drawableMin, Math.min(next, currentPage.drawableMax));
    loadAndRender();
  }

  function resetPending() {
    const committed = readCommitted(selectedTitle);
    if (!committed) return;
    pendingSelection = { ...committed };
    hoverRestoreToken += 1;
    restoreSelection(selectedTitle, committed).then(() => {
      pageStart = Math.floor(Math.max(0, committed.drawable) / PAGE_SIZE) * PAGE_SIZE;
      loadAndRender();
    });
  }

  function applyPending() {
    if (!pendingSelection) return;
    const card = cardsByTitle.get(selectedTitle);
    const inputs = card && getInputs(card);
    if (!inputs) return;

    hoverRestoreToken += 1;
    nativeSetValue(inputs.drawable, pendingSelection.drawable);
    nativeSetValue(inputs.texture, pendingSelection.texture);

    // Keep the ped exactly on the catalog selection while React catches up.
    previewSelection(selectedTitle, pendingSelection).finally(() => {
      window.setTimeout(() => {
        const committed = readCommitted(selectedTitle);
        if (committed) pendingSelection = { ...committed };
        if (currentPage) renderPage(currentPage);
      }, 120);
    });
  }

  function enhanceCard(card, title, config) {
    const existing = stateByCard.get(card);
    if (existing) return;
    stateByCard.set(card, { title, config });
    cardsByTitle.set(title, card);
    if (config.kind === "component") card.classList.add("sv-original-clothing-card");
  }

  function setupBrowserIfReady() {
    const componentCards = CLOTHING_ORDER.map((title) => cardsByTitle.get(title)).filter(Boolean);
    if (componentCards.length < 5) return;

    const mount = lowestCommonAncestor(componentCards);
    if (!mount) return;

    detectPanel(mount);

    if (browserRoot && browserRoot.isConnected && browserMount === mount) {
      renderCategories();
      return;
    }

    if (browserRoot?.isConnected) browserRoot.remove();
    browserMount = mount;
    browserRoot = buildShell();
    mount.insertBefore(browserRoot, mount.firstChild);

    const available = getAvailableTitles();
    if (!available.includes(selectedTitle)) selectedTitle = available[0] || "Jackets";
    const committed = readCommitted(selectedTitle);
    pendingSelection = committed ? { ...committed } : null;
    pageStart = committed ? Math.floor(Math.max(0, committed.drawable) / PAGE_SIZE) * PAGE_SIZE : 0;
    loadAndRender();
  }

  function scan() {
    scanQueued = false;
    if (!document.body) return;
    injectStyles();

    for (const [title, config] of CATEGORY_MAP) {
      for (const titleElement of findTitleElements(title)) {
        const card = findCard(titleElement);
        if (card) enhanceCard(card, title, config);
      }
    }

    // Drop stale nodes after React replaces a category card.
    for (const [title, card] of cardsByTitle) {
      if (!card.isConnected) cardsByTitle.delete(title);
    }

    setupBrowserIfReady();
  }

  function queueScan() {
    if (scanQueued) return;
    scanQueued = true;
    window.requestAnimationFrame(scan);
  }

  const observer = new MutationObserver(queueScan);

  function start() {
    injectStyles();
    observer.observe(document.body, { childList: true, subtree: true });
    queueScan();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start, { once: true });
  } else {
    start();
  }
})();
