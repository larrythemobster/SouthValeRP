(() => {
  "use strict";

  /*
   * SouthVale Character Studio
   *
   * This deliberately does NOT replace Illenium's React inputs or its save logic.
   * The stock controls stay mounted and own all state/NUI callbacks; this layer only
   * reorganizes the seven top-level accordion sections into a stable tabbed studio.
   * That makes the redesign resilient to component/prop ranges, blacklists, tattoos,
   * model changes, and Qbox persistence without duplicating any appearance state.
   */

  const SECTIONS = [
    { title: "Ped", label: "Identity", short: "ID" },
    { title: "Inheritance", label: "Genetics", short: "DNA" },
    { title: "Face Features", label: "Face", short: "FACE" },
    { title: "Appearance", label: "Grooming", short: "LOOK" },
    { title: "Clothes", label: "Clothing", short: "FIT" },
    { title: "Props", label: "Accessories", short: "ACC" },
    { title: "Tattoos", label: "Tattoos", short: "INK" }
  ];

  const SAVE_PATH = "M433.941 129.941l-83.882-83.882";
  const EXIT_PATH = "M242.72 256l100.07-100.07";

  let panel = null;
  let chrome = null;
  let activeTitle = "Ped";
  let queued = false;
  const sectionNodes = new Map();

  function injectStyles() {
    if (document.getElementById("southvale-studio-style")) return;

    const style = document.createElement("style");
    style.id = "southvale-studio-style";
    style.textContent = `
      :root {
        --sv-bg: 10, 10, 13;
        --sv-panel: 17, 17, 22;
        --sv-card: 25, 25, 32;
        --sv-card-2: 31, 31, 39;
        --sv-line: 255, 255, 255;
        --sv-text: 246, 246, 248;
        --sv-muted: 151, 151, 164;
        --sv-accent: 220, 20, 60;
        --sv-accent-2: 255, 58, 92;
      }

      .sv-studio-panel {
        position: fixed !important;
        top: 18px !important;
        right: 18px !important;
        left: auto !important;
        width: min(510px, calc(100vw - 36px)) !important;
        max-width: 510px !important;
        height: calc(100vh - 36px) !important;
        box-sizing: border-box !important;
        display: block !important;
        padding: 132px 16px 88px !important;
        overflow-x: hidden !important;
        overflow-y: auto !important;
        z-index: 8100 !important;
        border: 1px solid rgba(var(--sv-line), .09) !important;
        border-radius: 20px !important;
        background:
          radial-gradient(120% 80% at 100% 0%, rgba(var(--sv-accent), .13), transparent 46%),
          linear-gradient(180deg, rgba(var(--sv-panel), .985), rgba(var(--sv-bg), .985)) !important;
        box-shadow: 0 28px 90px rgba(0, 0, 0, .5) !important;
        backdrop-filter: blur(16px) !important;
      }

      .sv-studio-panel::-webkit-scrollbar { width: 5px !important; }
      .sv-studio-panel::-webkit-scrollbar-track { background: transparent !important; }
      .sv-studio-panel::-webkit-scrollbar-thumb {
        background: rgba(var(--sv-line), .16) !important;
        border-radius: 999px !important;
      }

      .sv-studio-panel > .sv-section { display: none !important; width: 100% !important; }
      .sv-studio-panel > .sv-section.is-active { display: block !important; }

      /* Hide Illenium's accordion header. The content stays mounted and functional. */
      .sv-studio-panel > .sv-section > :first-child { display: none !important; }
      .sv-studio-panel > .sv-section.is-active > :nth-child(2) {
        display: block !important;
        height: auto !important;
        opacity: 1 !important;
        overflow: visible !important;
        transform: none !important;
      }
      .sv-studio-panel > .sv-section.is-active > :nth-child(2) > div {
        padding: 0 !important;
        overflow: visible !important;
      }

      /* Original inner groups become clean cards instead of nested black slabs. */
      .sv-studio-panel > .sv-section.is-active > :nth-child(2) > div > div {
        box-sizing: border-box !important;
        margin: 0 0 10px !important;
        padding: 13px !important;
        border: 1px solid rgba(var(--sv-line), .075) !important;
        border-radius: 12px !important;
        background: linear-gradient(180deg, rgba(var(--sv-card), .88), rgba(var(--sv-card), .66)) !important;
        box-shadow: none !important;
      }

      .sv-studio-panel small,
      .sv-studio-panel span {
        font-family: Inter, Poppins, Arial, sans-serif !important;
      }

      .sv-studio-panel input[type="number"] {
        min-height: 34px !important;
        border: 1px solid rgba(var(--sv-line), .08) !important;
        border-radius: 7px !important;
        background: rgba(var(--sv-bg), .9) !important;
        color: rgb(var(--sv-text)) !important;
        font-weight: 700 !important;
      }

      .sv-studio-panel input[type="range"] {
        accent-color: rgb(var(--sv-accent-2)) !important;
      }

      .sv-studio-panel button {
        transition: background .12s ease, border-color .12s ease, transform .12s ease !important;
      }

      .sv-studio-panel button:hover { transform: none !important; }

      .sv-studio-chrome {
        position: fixed;
        top: 18px;
        right: 18px;
        width: min(510px, calc(100vw - 36px));
        height: 116px;
        box-sizing: border-box;
        z-index: 8200;
        padding: 17px 16px 10px;
        border-radius: 20px 20px 0 0;
        background: linear-gradient(180deg, rgba(17, 17, 22, .995) 70%, rgba(17, 17, 22, .94));
        pointer-events: auto;
        color: rgb(var(--sv-text));
        font-family: Inter, Poppins, Arial, sans-serif;
      }

      .sv-studio-topline {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 14px;
        margin-bottom: 13px;
      }

      .sv-studio-brand { min-width: 0; }
      .sv-studio-brand strong {
        display: block;
        font-size: 15px;
        line-height: 1;
        font-weight: 900;
        letter-spacing: .16em;
        text-transform: uppercase;
      }
      .sv-studio-brand span {
        display: block;
        margin-top: 6px;
        color: rgba(var(--sv-muted), .95);
        font-size: 9px;
        font-weight: 650;
        letter-spacing: .05em;
      }

      .sv-studio-active {
        flex: 0 0 auto;
        padding: 6px 9px;
        border: 1px solid rgba(var(--sv-accent-2), .25);
        border-radius: 999px;
        background: rgba(var(--sv-accent), .09);
        color: rgb(var(--sv-accent-2));
        font-size: 8px;
        font-weight: 900;
        letter-spacing: .12em;
        text-transform: uppercase;
      }

      .sv-studio-tabs {
        display: grid;
        grid-template-columns: repeat(7, minmax(0, 1fr));
        gap: 5px;
      }

      .sv-studio-tab {
        min-width: 0;
        height: 43px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 3px;
        padding: 4px 2px;
        border: 1px solid rgba(var(--sv-line), .06);
        border-radius: 8px;
        background: rgba(var(--sv-card), .54);
        color: rgba(var(--sv-muted), .95);
        cursor: pointer;
      }
      .sv-studio-tab:hover {
        border-color: rgba(var(--sv-line), .13);
        background: rgba(var(--sv-card-2), .82);
        color: rgb(var(--sv-text));
      }
      .sv-studio-tab.is-active {
        border-color: rgba(var(--sv-accent-2), .38);
        background: linear-gradient(180deg, rgba(var(--sv-accent), .18), rgba(var(--sv-accent), .08));
        color: rgb(var(--sv-text));
        box-shadow: inset 0 -2px 0 rgb(var(--sv-accent-2));
      }
      .sv-studio-tab b {
        font-size: 8px;
        line-height: 1;
        letter-spacing: .06em;
      }
      .sv-studio-tab span {
        max-width: 100%;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        font-size: 7px;
        font-weight: 700;
      }

      .sv-studio-footer {
        position: fixed;
        right: 18px;
        bottom: 18px;
        width: min(510px, calc(100vw - 36px));
        height: 72px;
        box-sizing: border-box;
        z-index: 8200;
        display: grid;
        grid-template-columns: 1fr auto auto;
        align-items: center;
        gap: 8px;
        padding: 11px 16px;
        border-top: 1px solid rgba(var(--sv-line), .07);
        border-radius: 0 0 20px 20px;
        background: linear-gradient(0deg, rgba(17, 17, 22, .995) 72%, rgba(17, 17, 22, .94));
        color: rgb(var(--sv-text));
        font-family: Inter, Poppins, Arial, sans-serif;
      }

      .sv-studio-help {
        min-width: 0;
        color: rgba(var(--sv-muted), .9);
        font-size: 8px;
        line-height: 1.35;
      }
      .sv-studio-help strong {
        display: block;
        margin-bottom: 3px;
        color: rgba(var(--sv-text), .92);
        font-size: 9px;
      }

      .sv-studio-action {
        height: 38px;
        min-width: 88px;
        padding: 0 14px;
        border-radius: 9px;
        border: 1px solid rgba(var(--sv-line), .1);
        background: rgba(var(--sv-card), .9);
        color: rgb(var(--sv-text));
        font-size: 9px;
        font-weight: 850;
        letter-spacing: .05em;
        text-transform: uppercase;
        cursor: pointer;
      }
      .sv-studio-action:hover { background: rgba(var(--sv-card-2), 1); }
      .sv-studio-action.primary {
        border-color: rgba(var(--sv-accent-2), .45);
        background: linear-gradient(180deg, rgba(var(--sv-accent-2), .96), rgba(var(--sv-accent), .96));
        color: white;
      }
      .sv-studio-action.primary:hover { filter: brightness(1.08); }
      .sv-studio-action[hidden] { display: none !important; }

      @media (max-width: 1050px) {
        .sv-studio-panel { width: min(470px, calc(100vw - 24px)) !important; right: 12px !important; top: 12px !important; height: calc(100vh - 24px) !important; }
        .sv-studio-chrome, .sv-studio-footer { width: min(470px, calc(100vw - 24px)); right: 12px; }
        .sv-studio-chrome { top: 12px; }
        .sv-studio-footer { bottom: 12px; }
      }

      @media (max-height: 760px) {
        .sv-studio-panel { padding-top: 116px !important; padding-bottom: 74px !important; }
        .sv-studio-chrome { height: 101px; padding-top: 12px; }
        .sv-studio-topline { margin-bottom: 8px; }
        .sv-studio-tab { height: 37px; }
        .sv-studio-footer { height: 62px; padding-top: 8px; padding-bottom: 8px; }
        .sv-studio-action { height: 34px; }
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

  function findTitle(title) {
    for (const span of document.querySelectorAll("span")) {
      if (directText(span) === title) return span;
    }
    return null;
  }

  function resolveSection(title) {
    const titleSpan = findTitle(title);
    if (!titleSpan) return null;

    const header = titleSpan.parentElement;
    const section = header && header.parentElement;
    if (!header || !section || section === document.body) return null;
    if (!header.contains(titleSpan) || section.children.length < 2) return null;
    return section;
  }

  function lowestCommonAncestor(nodes) {
    if (!nodes.length) return null;
    let candidate = nodes[0].parentElement;
    while (candidate && candidate !== document.body) {
      if (nodes.every((node) => candidate.contains(node))) return candidate;
      candidate = candidate.parentElement;
    }
    return null;
  }

  function findActionButton(pathPrefix) {
    for (const path of document.querySelectorAll("button svg path")) {
      const d = path.getAttribute("d") || "";
      if (d.startsWith(pathPrefix)) return path.closest("button");
    }
    return null;
  }

  function setActive(title) {
    if (!sectionNodes.has(title)) return;
    activeTitle = title;

    for (const [name, node] of sectionNodes) {
      node.classList.toggle("is-active", name === title);
    }

    if (!chrome) return;
    for (const button of chrome.querySelectorAll("[data-sv-section]")) {
      button.classList.toggle("is-active", button.dataset.svSection === title);
    }

    const definition = SECTIONS.find((entry) => entry.title === title);
    const active = chrome.querySelector("[data-sv-active]");
    if (active) active.textContent = definition ? definition.label : title;

    panel?.scrollTo({ top: 0, behavior: "auto" });
  }

  function buildChrome() {
    const wrapper = document.createElement("div");
    wrapper.id = "southvale-character-studio";
    wrapper.innerHTML = `
      <div class="sv-studio-chrome">
        <div class="sv-studio-topline">
          <div class="sv-studio-brand">
            <strong>SouthVale Studio</strong>
            <span>Character customization</span>
          </div>
          <div class="sv-studio-active" data-sv-active>Identity</div>
        </div>
        <nav class="sv-studio-tabs" data-sv-tabs></nav>
      </div>
      <div class="sv-studio-footer">
        <div class="sv-studio-help">
          <strong>Changes preview instantly</strong>
          Camera and rotate controls remain on the left side of the screen.
        </div>
        <button class="sv-studio-action" type="button" data-sv-exit>Cancel</button>
        <button class="sv-studio-action primary" type="button" data-sv-save>Save Character</button>
      </div>
    `;

    wrapper.addEventListener("click", (event) => {
      const tab = event.target.closest("[data-sv-section]");
      if (tab) {
        setActive(tab.dataset.svSection);
        return;
      }

      if (event.target.closest("[data-sv-save]")) {
        findActionButton(SAVE_PATH)?.click();
        return;
      }

      if (event.target.closest("[data-sv-exit]")) {
        findActionButton(EXIT_PATH)?.click();
      }
    });

    document.body.appendChild(wrapper);
    return wrapper;
  }

  function renderTabs() {
    if (!chrome) return;
    const tabs = chrome.querySelector("[data-sv-tabs]");
    if (!tabs) return;

    tabs.replaceChildren(...SECTIONS.filter((entry) => sectionNodes.has(entry.title)).map((entry) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = `sv-studio-tab${entry.title === activeTitle ? " is-active" : ""}`;
      button.dataset.svSection = entry.title;
      button.title = entry.label;
      button.innerHTML = `<b>${entry.short}</b><span>${entry.label}</span>`;
      return button;
    }));

    const save = chrome.querySelector("[data-sv-save]");
    const exit = chrome.querySelector("[data-sv-exit]");
    if (save) save.hidden = !findActionButton(SAVE_PATH);
    if (exit) exit.hidden = !findActionButton(EXIT_PATH);
  }

  function clearStudio() {
    if (panel) panel.classList.remove("sv-studio-panel");
    for (const node of sectionNodes.values()) {
      node.classList.remove("sv-section", "is-active");
    }
    sectionNodes.clear();
    panel = null;
    if (chrome) {
      chrome.remove();
      chrome = null;
    }
  }

  function scan() {
    queued = false;
    injectStyles();

    const found = new Map();
    for (const definition of SECTIONS) {
      const node = resolveSection(definition.title);
      if (node && node.isConnected) found.set(definition.title, node);
    }

    /* The appearance view is considered present once a few canonical sections exist. */
    if (found.size < 3) {
      if (panel || chrome) clearStudio();
      return;
    }

    const nodes = [...found.values()];
    const nextPanel = lowestCommonAncestor(nodes);
    if (!nextPanel) return;

    if (panel && panel !== nextPanel) clearStudio();
    panel = nextPanel;
    panel.classList.add("sv-studio-panel");

    sectionNodes.clear();
    for (const [title, node] of found) {
      node.classList.add("sv-section");
      sectionNodes.set(title, node);
    }

    if (!sectionNodes.has(activeTitle)) {
      activeTitle = sectionNodes.has("Ped") ? "Ped" : sectionNodes.keys().next().value;
    }

    if (!chrome || !chrome.isConnected) chrome = buildChrome();
    renderTabs();
    setActive(activeTitle);
  }

  function queueScan() {
    if (queued) return;
    queued = true;
    requestAnimationFrame(scan);
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
