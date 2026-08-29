(() => {
  "use strict";

  const RESOURCE = typeof GetParentResourceName === "function"
    ? GetParentResourceName()
    : "illenium-appearance";

  const CATEGORY_MAP = new Map([
    ["Head", { kind: "component", id: 0 }],
    ["Mask", { kind: "component", id: 1 }],
    ["Scarf and chains", { kind: "component", id: 7 }],
    ["Jackets", { kind: "component", id: 11 }],
    ["Shirt", { kind: "component", id: 8 }],
    ["Body armor", { kind: "component", id: 9 }],
    ["Bags and parachute", { kind: "component", id: 5 }],
    ["Hands", { kind: "component", id: 3 }],
    ["Legs", { kind: "component", id: 4 }],
    ["Shoes", { kind: "component", id: 6 }],
    ["Decals", { kind: "component", id: 10 }],
    ["Hats and helmets", { kind: "prop", id: 0 }],
    ["Glasses", { kind: "prop", id: 1 }],
    ["Ear", { kind: "prop", id: 2 }],
    ["Watches", { kind: "prop", id: 6 }],
    ["Bracelets", { kind: "prop", id: 7 }]
  ]);

  const stateByCard = new WeakMap();
  let scanQueued = false;

  function post(name, payload) {
    return fetch(`https://${RESOURCE}/${name}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(payload || {})
    }).then((response) => response.json());
  }

  function injectStyles() {
    if (document.getElementById("southvale-clothing-browser-style")) return;

    const style = document.createElement("style");
    style.id = "southvale-clothing-browser-style";
    style.textContent = `
      .sv-clothing-card {
        position: relative !important;
        border: 1px solid rgba(255,255,255,.06) !important;
        border-radius: 7px !important;
        background: linear-gradient(135deg, rgba(12,12,14,.88), rgba(19,19,22,.67)) !important;
        box-shadow: 0 6px 16px rgba(0,0,0,.14) !important;
        padding: 9px 10px 8px !important;
        margin-bottom: 7px !important;
      }

      .sv-clothing-card-title {
        display: inline-flex !important;
        align-items: center !important;
        min-height: 21px !important;
        font-weight: 700 !important;
        letter-spacing: .01em !important;
      }

      .sv-clothing-card input[type="number"] {
        font-weight: 650 !important;
        font-size: 14px !important;
        border: 1px solid rgba(255,255,255,.05) !important;
      }

      .sv-clothing-card input[type="number"]:focus {
        outline: 1px solid rgba(229,16,62,.72) !important;
        box-shadow: 0 0 0 2px rgba(229,16,62,.12) !important;
      }

      .sv-clothing-card button[data-sv-arrow="1"] {
        min-width: 34px !important;
        border: 1px solid rgba(255,255,255,.055) !important;
        transition: background .10s ease, border-color .10s ease, transform .10s ease !important;
      }

      .sv-clothing-card button[data-sv-arrow="1"]:hover,
      .sv-clothing-card button[data-sv-arrow="1"].sv-preview-arrow {
        transform: translateY(-1px) !important;
        border-color: rgba(229,16,62,.70) !important;
        background: rgba(229,16,62,.24) !important;
      }

      .sv-preview-line {
        width: 100%;
        min-height: 24px;
        display: flex;
        align-items: center;
        gap: 6px;
        margin-top: 6px;
        padding: 5px 7px;
        border-top: 1px solid rgba(255,255,255,.055);
        color: rgba(255,255,255,.56);
        font-size: 9px;
        line-height: 1.25;
        overflow: hidden;
      }

      .sv-preview-pill {
        flex: 0 0 auto;
        padding: 2px 5px;
        border-radius: 3px;
        background: rgba(255,255,255,.07);
        color: rgba(255,255,255,.65);
        font-size: 8px;
        font-weight: 800;
        letter-spacing: .06em;
        text-transform: uppercase;
      }

      .sv-preview-text {
        min-width: 0;
        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;
      }

      .sv-preview-line.sv-previewing {
        color: rgba(255,255,255,.95);
      }

      .sv-preview-line.sv-previewing .sv-preview-pill {
        background: rgba(229,16,62,.28);
        color: rgb(255,115,146);
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

  function payloadFor(card, config) {
    const inputs = getInputs(card);
    if (!inputs) return null;

    return {
      kind: config.kind,
      id: config.id,
      drawable: numberValue(inputs.drawable, config.kind === "prop" ? -1 : 0),
      texture: numberValue(inputs.texture, config.kind === "prop" ? -1 : 0)
    };
  }

  function ensureStatus(card) {
    let status = card.querySelector(":scope > .sv-preview-line");
    if (status) return status;

    status = document.createElement("div");
    status.className = "sv-preview-line";

    const pill = document.createElement("span");
    pill.className = "sv-preview-pill";
    pill.textContent = "Preview";

    const text = document.createElement("span");
    text.className = "sv-preview-text";

    status.append(pill, text);
    card.appendChild(status);
    return status;
  }

  function categoryName(card) {
    const state = stateByCard.get(card);
    return state ? state.title : "Item";
  }

  function currentDescription(card) {
    const state = stateByCard.get(card);
    const inputs = getInputs(card);
    if (!state || !inputs) return "Hover an arrow to preview before equipping.";

    const drawable = numberValue(inputs.drawable, state.config.kind === "prop" ? -1 : 0);
    const texture = numberValue(inputs.texture, state.config.kind === "prop" ? -1 : 0);
    const item = drawable < 0 ? "None" : `#${drawable}`;
    const variant = texture < 0 ? "" : ` · Variant ${texture}`;
    return `Equipped: ${state.title} ${item}${variant} · Hover ‹ or › to preview`;
  }

  function setStatus(card, message, previewing) {
    const status = ensureStatus(card);
    const pill = status.querySelector(".sv-preview-pill");
    const text = status.querySelector(".sv-preview-text");
    if (pill) pill.textContent = previewing ? "Previewing" : "Preview";
    if (text) text.textContent = message;
    status.classList.toggle("sv-previewing", Boolean(previewing));
  }

  function restoreCard(card, config) {
    const state = stateByCard.get(card);
    if (!state) return;

    const restoreToken = ++state.restoreToken;
    window.setTimeout(() => {
      if (!card.isConnected || restoreToken !== state.restoreToken) return;
      const payload = payloadFor(card, config);
      if (!payload) return;

      post("appearance_restore_clothing", payload).catch(() => {});
      state.previewActive = false;
      setStatus(card, currentDescription(card), false);
    }, 0);
  }

  function previewStep(card, config, axis, direction, button) {
    const state = stateByCard.get(card);
    const payload = payloadFor(card, config);
    if (!state || !payload) return;

    state.previewActive = true;
    state.restoreToken += 1;
    button.classList.add("sv-preview-arrow");

    post("appearance_preview_clothing_step", {
      ...payload,
      axis,
      direction
    }).then((preview) => {
      if (!card.isConnected || !state.previewActive) return;

      const item = preview.drawable < 0 ? "None" : `#${preview.drawable}`;
      const variant = preview.texture < 0 ? "" : ` · Variant ${preview.texture}`;
      setStatus(
        card,
        `${categoryName(card)} ${item}${variant} · Click arrow to equip`,
        true
      );
    }).catch(() => {});
  }

  function bindArrowPreview(card, config, input, axis) {
    const controls = input.parentElement;
    if (!controls) return;

    const arrows = Array.from(controls.querySelectorAll("button"));
    if (arrows.length < 2) return;

    arrows.forEach((button, index) => {
      if (button.dataset.svArrow === "1") return;
      button.dataset.svArrow = "1";
      const direction = index === 0 ? -1 : 1;
      button.title = `${direction < 0 ? "Preview previous" : "Preview next"} ${axis === "drawable" ? "item" : "variant"} — click to equip`;

      button.addEventListener("mouseenter", () => {
        previewStep(card, config, axis, direction, button);
      });

      button.addEventListener("mouseleave", () => {
        button.classList.remove("sv-preview-arrow");
        restoreCard(card, config);
      });

      button.addEventListener("click", () => {
        const state = stateByCard.get(card);
        if (state) {
          state.previewActive = false;
          state.restoreToken += 1;
        }
        button.classList.remove("sv-preview-arrow");
        window.setTimeout(() => setStatus(card, currentDescription(card), false), 90);
      });
    });
  }

  function enhanceCard(card, titleElement, title, config) {
    if (stateByCard.has(card)) return;

    card.classList.add("sv-clothing-card");
    titleElement.classList.add("sv-clothing-card-title");
    stateByCard.set(card, {
      title,
      config,
      previewActive: false,
      restoreToken: 0
    });

    const inputs = getInputs(card);
    if (!inputs) return;

    bindArrowPreview(card, config, inputs.drawable, "drawable");
    bindArrowPreview(card, config, inputs.texture, "texture");

    const updateStatus = () => window.setTimeout(() => {
      const state = stateByCard.get(card);
      if (state && !state.previewActive) setStatus(card, currentDescription(card), false);
    }, 90);

    inputs.drawable.addEventListener("change", updateStatus);
    inputs.texture.addEventListener("change", updateStatus);
    inputs.drawable.addEventListener("input", updateStatus);
    inputs.texture.addEventListener("input", updateStatus);

    setStatus(card, currentDescription(card), false);
  }

  function scan() {
    scanQueued = false;
    if (!document.body) return;
    injectStyles();

    for (const [title, config] of CATEGORY_MAP) {
      for (const titleElement of findTitleElements(title)) {
        const card = findCard(titleElement);
        if (card) enhanceCard(card, titleElement, title, config);
      }
    }
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
