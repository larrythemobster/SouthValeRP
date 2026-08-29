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
        border: 1px solid rgba(255,255,255,.075) !important;
        border-radius: 7px !important;
        background: linear-gradient(135deg, rgba(12,12,14,.91), rgba(19,19,22,.72)) !important;
        box-shadow: 0 8px 20px rgba(0,0,0,.17) !important;
        padding: 10px 10px 11px !important;
        margin-bottom: 8px !important;
      }

      .sv-clothing-card-title {
        display: inline-flex !important;
        align-items: center !important;
        min-height: 22px !important;
        font-weight: 700 !important;
        letter-spacing: .01em !important;
      }

      .sv-clothing-card input[type="number"] {
        font-weight: 650 !important;
        font-size: 14px !important;
        border: 1px solid rgba(255,255,255,.055) !important;
      }

      .sv-clothing-card input[type="number"]:focus {
        outline: 1px solid rgba(229,16,62,.72) !important;
        box-shadow: 0 0 0 2px rgba(229,16,62,.13) !important;
      }

      .sv-clothing-card button[data-sv-arrow="1"] {
        min-width: 34px !important;
        border: 1px solid rgba(255,255,255,.055) !important;
        transition: transform .12s ease, background .12s ease, border-color .12s ease !important;
      }

      .sv-clothing-card button[data-sv-arrow="1"]:hover {
        transform: translateY(-1px) !important;
        border-color: rgba(229,16,62,.55) !important;
        background: rgba(229,16,62,.23) !important;
      }

      .sv-browser {
        width: 100%;
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 5px;
        margin-top: 9px;
        padding-top: 8px;
        border-top: 1px solid rgba(255,255,255,.07);
      }

      .sv-browser-option {
        min-width: 0;
        min-height: 55px;
        display: flex;
        flex-direction: column;
        align-items: stretch;
        justify-content: center;
        gap: 3px;
        padding: 6px 6px;
        color: rgba(255,255,255,.92);
        background: rgba(0,0,0,.32);
        border: 1px solid rgba(255,255,255,.07);
        border-radius: 5px;
        cursor: pointer;
        text-align: left;
        overflow: hidden;
        transition: border-color .12s ease, background .12s ease, transform .12s ease;
      }

      .sv-browser-option:hover {
        border-color: rgba(229,16,62,.62);
        background: rgba(229,16,62,.15);
        transform: translateY(-1px);
      }

      .sv-browser-option.sv-current {
        cursor: default;
        border-color: rgba(229,16,62,.72);
        background: rgba(229,16,62,.22);
      }

      .sv-browser-option.sv-current:hover {
        transform: none;
      }

      .sv-browser-option img {
        width: 100%;
        aspect-ratio: 1.25 / 1;
        object-fit: contain;
        border-radius: 4px;
        background: radial-gradient(circle, rgba(255,255,255,.10), rgba(0,0,0,.18));
        margin-bottom: 2px;
      }

      .sv-browser-kicker {
        display: block;
        color: rgba(255,255,255,.48);
        font-size: 8px;
        font-weight: 800;
        letter-spacing: .08em;
        text-transform: uppercase;
      }

      .sv-browser-name {
        display: block;
        min-width: 0;
        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;
        font-size: 10px;
        line-height: 1.25;
        font-weight: 650;
      }

      .sv-browser-id {
        display: block;
        color: rgba(255,255,255,.55);
        font-size: 9px;
        line-height: 1.1;
      }

      .sv-browser-help {
        grid-column: 1 / -1;
        min-height: 14px;
        display: flex;
        align-items: center;
        color: rgba(255,255,255,.50);
        font-size: 9px;
        line-height: 1.3;
        padding: 1px 1px 0;
      }

      .sv-browser-help.sv-previewing {
        color: rgba(255,255,255,.88);
      }

      .sv-browser-help strong {
        color: rgb(255,87,124);
        font-weight: 800;
        margin-right: 3px;
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

  function setHelp(card, message, previewing) {
    const help = card.querySelector(".sv-browser-help");
    if (!help) return;
    help.textContent = "";
    if (previewing) {
      const strong = document.createElement("strong");
      strong.textContent = "PREVIEW";
      help.appendChild(strong);
    }
    help.appendChild(document.createTextNode(message));
    help.classList.toggle("sv-previewing", Boolean(previewing));
  }

  function optionButton(role, option, card, config) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = `sv-browser-option sv-${role}`;
    if (role === "current") button.classList.add("sv-current");

    if (option.thumbnail) {
      const image = document.createElement("img");
      image.src = option.thumbnail;
      image.alt = "";
      image.loading = "lazy";
      image.addEventListener("error", () => image.remove(), { once: true });
      button.appendChild(image);
    }

    const kicker = document.createElement("span");
    kicker.className = "sv-browser-kicker";
    kicker.textContent = role === "previous" ? "Previous" : role === "next" ? "Next" : "Equipped";

    const name = document.createElement("span");
    name.className = "sv-browser-name";
    name.textContent = option.label || `Item ${option.drawable}`;
    name.title = option.label || "";

    const id = document.createElement("span");
    id.className = "sv-browser-id";
    id.textContent = option.drawable < 0
      ? "None"
      : `Item ${option.drawable} · Variant ${Math.max(0, option.texture)}`;

    button.append(kicker, name, id);

    if (role !== "current") {
      button.addEventListener("mouseenter", () => {
        const currentState = stateByCard.get(card);
        if (currentState) currentState.previewActive = true;
        post("appearance_preview_clothing", {
          kind: config.kind,
          id: config.id,
          drawable: option.drawable,
          texture: option.texture
        }).then((preview) => {
          setHelp(card, ` ${preview.label || option.label} — click to equip`, true);
        }).catch(() => {});
      });

      button.addEventListener("mouseleave", () => restoreCard(card, config));

      button.addEventListener("click", () => {
        const inputs = getInputs(card);
        if (!inputs) return;
        const control = inputs.drawable.parentElement;
        if (!control) return;
        const arrows = Array.from(control.querySelectorAll("button"));
        const target = role === "previous" ? arrows[0] : arrows[arrows.length - 1];
        if (target) target.click();
      });
    }

    return button;
  }

  function renderBrowser(card, config, data) {
    let browser = card.querySelector(":scope > .sv-browser");
    if (!browser) {
      browser = document.createElement("div");
      browser.className = "sv-browser";
      card.appendChild(browser);
    }

    browser.textContent = "";
    browser.appendChild(optionButton("previous", data.previous, card, config));
    browser.appendChild(optionButton("current", data.current, card, config));
    browser.appendChild(optionButton("next", data.next, card, config));

    const help = document.createElement("div");
    help.className = "sv-browser-help";
    help.textContent = "Hover a choice to preview it on your character. Click to equip.";
    browser.appendChild(help);
  }

  function refreshCard(card, config) {
    const state = stateByCard.get(card);
    if (!state || state.previewActive) return;

    const payload = payloadFor(card, config);
    if (!payload) return;

    const requestId = ++state.requestId;
    post("appearance_get_clothing_browser", payload)
      .then((data) => {
        if (!card.isConnected || requestId !== state.requestId) return;
        state.browserData = data;
        renderBrowser(card, config, data);
      })
      .catch(() => {});
  }

  function restoreCard(card, config) {
    const state = stateByCard.get(card);
    if (!state) return;

    window.setTimeout(() => {
      const payload = payloadFor(card, config);
      if (!payload) return;
      post("appearance_restore_clothing", payload).catch(() => {});
      state.previewActive = false;
      setHelp(card, "Hover a choice to preview it on your character. Click to equip.", false);
      window.setTimeout(() => refreshCard(card, config), 50);
    }, 0);
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
      button.title = `${direction < 0 ? "Preview previous" : "Preview next"} ${axis === "drawable" ? "item" : "variant"}`;

      button.addEventListener("mouseenter", () => {
        const state = stateByCard.get(card);
        const payload = payloadFor(card, config);
        if (!state || !payload) return;
        state.previewActive = true;

        post("appearance_preview_clothing_step", {
          ...payload,
          axis,
          direction
        }).then((preview) => {
          const suffix = axis === "texture"
            ? ` · variant ${Math.max(0, preview.texture)}`
            : "";
          setHelp(card, ` ${preview.label || "Item"}${suffix} — click to equip`, true);
        }).catch(() => {});
      });

      button.addEventListener("mouseleave", () => restoreCard(card, config));
      button.addEventListener("click", () => window.setTimeout(() => {
        const state = stateByCard.get(card);
        if (state) state.previewActive = false;
        refreshCard(card, config);
      }, 80));
    });
  }

  function enhanceCard(card, titleElement, config) {
    if (stateByCard.has(card)) return;

    card.classList.add("sv-clothing-card");
    titleElement.classList.add("sv-clothing-card-title");
    stateByCard.set(card, { requestId: 0, previewActive: false, browserData: null });

    const inputs = getInputs(card);
    if (!inputs) return;

    bindArrowPreview(card, config, inputs.drawable, "drawable");
    bindArrowPreview(card, config, inputs.texture, "texture");

    inputs.drawable.addEventListener("change", () => window.setTimeout(() => refreshCard(card, config), 80));
    inputs.texture.addEventListener("change", () => window.setTimeout(() => refreshCard(card, config), 80));
    inputs.drawable.addEventListener("input", () => window.setTimeout(() => refreshCard(card, config), 80));
    inputs.texture.addEventListener("input", () => window.setTimeout(() => refreshCard(card, config), 80));

    refreshCard(card, config);
  }

  function scan() {
    scanQueued = false;
    if (!document.body) return;
    injectStyles();

    for (const [title, config] of CATEGORY_MAP) {
      for (const titleElement of findTitleElements(title)) {
        const card = findCard(titleElement);
        if (card) enhanceCard(card, titleElement, config);
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
