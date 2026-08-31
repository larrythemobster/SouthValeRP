const app = document.getElementById('app');
const nav = document.getElementById('category-nav');
const content = document.getElementById('editor-content');
const sectionIndex = document.getElementById('section-index');
const sectionTitle = document.getElementById('section-title');
const sectionCopy = document.getElementById('section-copy');
const previewTitle = document.getElementById('preview-title');
const genderLabel = document.getElementById('gender-label');
const toast = document.getElementById('toast');
const saveButton = document.getElementById('save-button');
const resetButton = document.getElementById('reset-button');
const savingOverlay = document.getElementById('saving-overlay');

const categories = [
    { id: 'heritage', label: 'Heritage', copy: 'Shape the foundation of your character.', camera: 'head', preview: 'Face' },
    { id: 'face', label: 'Face', copy: 'Fine-tune the proportions that make this face unique.', camera: 'head', preview: 'Face details' },
    { id: 'hair', label: 'Hair', copy: 'Choose hair, colour, highlights, and eye colour.', camera: 'head', preview: 'Head & hair' },
    { id: 'skin', label: 'Skin Details', copy: 'Add subtle details, facial hair, makeup, and complexion.', camera: 'head', preview: 'Skin details' },
    { id: 'clothing', label: 'Clothing', copy: 'Build the outfit your character arrives in.', camera: 'full', preview: 'Full outfit' },
    { id: 'accessories', label: 'Accessories', copy: 'Finish the look with hats, glasses, jewellery, and watches.', camera: 'full', preview: 'Accessories' },
];

let state = null;
let activeCategory = 'heritage';
let busy = false;
let sliderTimers = new Map();

function resourceName() {
    return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'sv_first_appearance';
}

async function post(endpoint, data = {}) {
    const response = await fetch(`https://${resourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    });
    return response.json();
}

function escapeHtml(value) {
    return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

function clamp(value, min, max) {
    const n = Number(value);
    if (!Number.isFinite(n)) return min;
    return Math.min(max, Math.max(min, n));
}

function showToast(message) {
    if (!message) return;
    toast.textContent = message;
    toast.classList.remove('is-hidden');
    clearTimeout(showToast.timer);
    showToast.timer = setTimeout(() => toast.classList.add('is-hidden'), 2600);
}

function throttle(key, fn, delay = 45) {
    clearTimeout(sliderTimers.get(key));
    sliderTimers.set(key, setTimeout(() => {
        sliderTimers.delete(key);
        fn();
    }, delay));
}

function renderNav() {
    nav.innerHTML = categories.map((category, index) => `
        <button class="category-button${category.id === activeCategory ? ' is-active' : ''}" data-category="${category.id}" type="button">
            <span class="category-number">${String(index + 1).padStart(2, '0')}</span>
            <span class="category-name">${escapeHtml(category.label)}</span>
            <span class="category-arrow">›</span>
        </button>
    `).join('');

    nav.querySelectorAll('.category-button').forEach((button) => {
        button.addEventListener('click', () => selectCategory(button.dataset.category));
    });
}

async function selectCategory(id) {
    const category = categories.find((entry) => entry.id === id);
    if (!category || !state) return;
    activeCategory = id;
    renderNav();
    renderEditor();
    previewTitle.textContent = category.preview;
    await post('cameraPreset', { preset: category.camera });
}

function stepper({ key, value, min, max, label, formatter }) {
    const display = formatter ? formatter(value) : `${value} <em>/ ${max}</em>`;
    return `
        <div class="stepper" data-stepper="${escapeHtml(key)}" data-min="${min}" data-max="${max}">
            <button type="button" data-step="-1" aria-label="Previous ${escapeHtml(label || '')}">−</button>
            <span class="stepper-value">${display}</span>
            <button type="button" data-step="1" aria-label="Next ${escapeHtml(label || '')}">＋</button>
        </div>
    `;
}

function rangeRow({ key, label, value, min, max, step, note }) {
    return `
        <div class="control-row range-row">
            <div class="control-label"><strong>${escapeHtml(label)}</strong>${note ? `<small>${escapeHtml(note)}</small>` : ''}</div>
            <div class="range-wrap">
                <input type="range" data-range="${escapeHtml(key)}" min="${min}" max="${max}" step="${step}" value="${value}">
                <span class="range-value" data-range-value="${escapeHtml(key)}">${Number(value).toFixed(step < 1 ? 1 : 0)}</span>
            </div>
        </div>
    `;
}

function sectionBlock(title, hint, inner) {
    return `
        <section class="control-section">
            <div class="control-section-title"><strong>${escapeHtml(title)}</strong><span>${escapeHtml(hint || '')}</span></div>
            ${inner}
        </section>
    `;
}

function renderHeritage() {
    const h = state.heritage;
    const parentRows = [
        ['shapeFirst', 'Face parent A', 'Primary facial structure'],
        ['shapeSecond', 'Face parent B', 'Secondary facial structure'],
        ['skinFirst', 'Skin parent A', 'Primary skin tone source'],
        ['skinSecond', 'Skin parent B', 'Secondary skin tone source'],
    ].map(([key, label, note]) => `
        <div class="control-row">
            <div class="control-label"><strong>${label}</strong><small>${note}</small></div>
            ${stepper({ key: `heritage:${key}`, value: h[key], min: 0, max: h.maxParent, label })}
        </div>
    `).join('');

    return `
        <div class="notice-card"><strong>Identity locked.</strong> Your character's gender comes from the identity you just created. This editor changes appearance only.</div>
        ${sectionBlock('Parent blend', 'Structure & tone', `<div class="control-card">${parentRows}</div>`)}
        ${sectionBlock('Blend balance', '0 = A · 1 = B', `
            <div class="control-card">
                ${rangeRow({ key: 'heritage:shapeMix', label: 'Facial resemblance', value: h.shapeMix, min: 0, max: 1, step: 0.05 })}
                ${rangeRow({ key: 'heritage:skinMix', label: 'Skin tone balance', value: h.skinMix, min: 0, max: 1, step: 0.05 })}
            </div>
        `)}
    `;
}

function renderFace() {
    const rows = state.faceFeatures.map((feature) => rangeRow({
        key: `face:${feature.key}`,
        label: feature.label,
        value: feature.value,
        min: -1,
        max: 1,
        step: 0.1,
    })).join('');
    return sectionBlock('Facial proportions', 'Fine adjustment', `<div class="control-card">${rows}</div>`);
}

function renderHair() {
    const hair = state.hair;
    const eyeName = state.eyeColors[state.eyeColor] || `Eye ${state.eyeColor}`;
    return `
        ${sectionBlock('Hair', 'Live preview', `
            <div class="control-card">
                <div class="control-row"><div class="control-label"><strong>Style</strong><small>Hair drawable</small></div>${stepper({ key: 'hair:style', value: hair.style, min: 0, max: hair.maxStyle, label: 'hair style' })}</div>
                <div class="control-row"><div class="control-label"><strong>Texture</strong><small>Style variation</small></div>${stepper({ key: 'hair:texture', value: hair.texture, min: 0, max: hair.maxTexture, label: 'hair texture' })}</div>
                <div class="control-row"><div class="control-label"><strong>Primary colour</strong><small>GTA hair palette</small></div>${stepper({ key: 'hair:color', value: hair.color, min: 0, max: hair.maxColor, label: 'hair colour' })}</div>
                <div class="control-row"><div class="control-label"><strong>Highlight</strong><small>Secondary hair colour</small></div>${stepper({ key: 'hair:highlight', value: hair.highlight, min: 0, max: hair.maxColor, label: 'hair highlight' })}</div>
            </div>
        `)}
        ${sectionBlock('Eyes', 'Colour', `
            <div class="control-card">
                <div class="control-row"><div class="control-label"><strong>Eye colour</strong><small>${escapeHtml(eyeName)}</small></div>${stepper({ key: 'eye:color', value: state.eyeColor, min: 0, max: state.eyeColors.length - 1, label: 'eye colour', formatter: () => escapeHtml(eyeName) })}</div>
            </div>
        `)}
    `;
}

function renderSkin() {
    const cards = state.overlays.map((overlay) => `
        <div class="item-card" data-overlay-card="${escapeHtml(overlay.key)}">
            <div class="item-card-head"><strong>${escapeHtml(overlay.label)}</strong><span>${overlay.opacity <= 0 ? 'OFF' : `${Math.round(overlay.opacity * 100)}%`}</span></div>
            <div class="item-controls">
                <div class="mini-control"><span>Style</span>${stepper({ key: `overlay:${overlay.key}:style`, value: overlay.style, min: 0, max: overlay.maxStyle, label: `${overlay.label} style` })}</div>
                ${overlay.colorType ? `<div class="mini-control"><span>Colour</span>${stepper({ key: `overlay:${overlay.key}:color`, value: overlay.color, min: 0, max: overlay.maxColor, label: `${overlay.label} colour` })}</div>` : '<div></div>'}
            </div>
            <div class="control-row range-row" style="padding: 11px 0 0; min-height: 38px; border: 0;">
                <div class="control-label"><small>Intensity</small></div>
                <div class="range-wrap">
                    <input type="range" data-range="overlay:${escapeHtml(overlay.key)}:opacity" min="0" max="1" step="0.1" value="${overlay.opacity}">
                    <span class="range-value" data-range-value="overlay:${escapeHtml(overlay.key)}:opacity">${Number(overlay.opacity).toFixed(1)}</span>
                </div>
            </div>
        </div>
    `).join('');
    return sectionBlock('Skin & detail', 'Set intensity to 0 to hide', cards);
}

function renderWearables(items, kind) {
    return items.map((item) => {
        const drawableLabel = kind === 'prop' && item.drawable === -1 ? 'None' : `${item.drawable} <em>/ ${item.maxDrawable}</em>`;
        return `
            <div class="item-card" data-wearable="${kind}:${item.id}" data-camera-preset="${item.camera}">
                <div class="item-card-head"><strong>${escapeHtml(item.label)}</strong><span>LIVE ON CHARACTER</span></div>
                <div class="item-controls">
                    <div class="mini-control"><span>Item</span>${stepper({ key: `${kind}:${item.id}:drawable`, value: item.drawable, min: kind === 'prop' ? -1 : 0, max: item.maxDrawable, label: item.label, formatter: () => drawableLabel })}</div>
                    <div class="mini-control"><span>Texture</span>${stepper({ key: `${kind}:${item.id}:texture`, value: item.texture, min: 0, max: item.maxTexture, label: `${item.label} texture` })}</div>
                </div>
            </div>
        `;
    }).join('');
}

function renderClothing() {
    return `
        <div class="notice-card"><strong>This is your arrival outfit.</strong> Every change is previewed on the actual character. Normal in-game clothing stores are not modified by this editor.</div>
        ${sectionBlock('Clothing', 'Item + texture', renderWearables(state.components, 'component'))}
    `;
}

function renderAccessories() {
    return sectionBlock('Accessories', 'Use item −1 for none', renderWearables(state.props, 'prop'));
}

function renderEditor() {
    if (!state) return;
    const category = categories.find((entry) => entry.id === activeCategory) || categories[0];
    const index = categories.indexOf(category);
    sectionIndex.textContent = `${String(index + 1).padStart(2, '0')} / ${String(categories.length).padStart(2, '0')}`;
    sectionTitle.textContent = category.label;
    sectionCopy.textContent = category.copy;

    if (category.id === 'heritage') content.innerHTML = renderHeritage();
    if (category.id === 'face') content.innerHTML = renderFace();
    if (category.id === 'hair') content.innerHTML = renderHair();
    if (category.id === 'skin') content.innerHTML = renderSkin();
    if (category.id === 'clothing') content.innerHTML = renderClothing();
    if (category.id === 'accessories') content.innerHTML = renderAccessories();

    bindEditorControls();
}

function getComponent(id) {
    return state.components.find((item) => item.id === Number(id));
}

function getProp(id) {
    return state.props.find((item) => item.id === Number(id));
}

function getOverlay(key) {
    return state.overlays.find((item) => item.key === key);
}

async function adjustStepper(key, delta) {
    if (!state || busy) return;
    const parts = key.split(':');

    if (parts[0] === 'heritage') {
        const field = parts[1];
        state.heritage[field] = clamp(Number(state.heritage[field]) + delta, 0, state.heritage.maxParent);
        await post('setHeritage', { values: { [field]: state.heritage[field] } });
        renderEditor();
        return;
    }

    if (parts[0] === 'hair') {
        const field = parts[1];
        const max = field === 'style' ? state.hair.maxStyle : field === 'texture' ? state.hair.maxTexture : state.hair.maxColor;
        state.hair[field] = clamp(Number(state.hair[field]) + delta, 0, max);
        const payload = { [field]: state.hair[field] };
        if (field === 'style') payload.texture = 0;
        const result = await post('setHair', payload);
        if (result.ok) {
            state.hair = { ...state.hair, ...result.hair, maxStyle: result.maxStyle, maxTexture: result.maxTexture, maxColor: result.maxColor };
        }
        renderEditor();
        return;
    }

    if (parts[0] === 'eye') {
        state.eyeColor = clamp(state.eyeColor + delta, 0, state.eyeColors.length - 1);
        const result = await post('setEyeColor', { value: state.eyeColor });
        if (result.ok) state.eyeColor = result.value;
        renderEditor();
        return;
    }

    if (parts[0] === 'overlay') {
        const overlay = getOverlay(parts[1]);
        const field = parts[2];
        if (!overlay) return;
        const max = field === 'style' ? overlay.maxStyle : overlay.maxColor;
        overlay[field] = clamp(Number(overlay[field]) + delta, 0, max);
        const result = await post('setOverlay', { key: overlay.key, [field]: overlay[field] });
        if (result.ok) Object.assign(overlay, result.overlay, { maxStyle: result.maxStyle, maxColor: result.maxColor });
        renderEditor();
        return;
    }

    if (parts[0] === 'component') {
        const item = getComponent(parts[1]);
        const field = parts[2];
        if (!item) return;
        if (field === 'drawable') {
            item.drawable = clamp(item.drawable + delta, 0, item.maxDrawable);
            item.texture = 0;
        } else {
            item.texture = clamp(item.texture + delta, 0, item.maxTexture);
        }
        const result = await post('setComponent', { id: item.id, drawable: item.drawable, texture: item.texture });
        if (result.ok) Object.assign(item, result);
        renderEditor();
        return;
    }

    if (parts[0] === 'prop') {
        const item = getProp(parts[1]);
        const field = parts[2];
        if (!item) return;
        if (field === 'drawable') {
            item.drawable = clamp(item.drawable + delta, -1, item.maxDrawable);
            item.texture = 0;
        } else {
            item.texture = clamp(item.texture + delta, 0, item.maxTexture);
        }
        const result = await post('setProp', { id: item.id, drawable: item.drawable, texture: item.texture });
        if (result.ok) Object.assign(item, result);
        renderEditor();
    }
}

function handleRange(input) {
    const key = input.dataset.range;
    const value = Number(input.value);
    const valueLabel = content.querySelector(`[data-range-value="${CSS.escape(key)}"]`);
    if (valueLabel) valueLabel.textContent = value.toFixed(Number(input.step) < 1 ? 1 : 0);

    const parts = key.split(':');
    if (parts[0] === 'heritage') {
        state.heritage[parts[1]] = value;
        throttle(key, () => post('setHeritage', { values: { [parts[1]]: value } }));
    } else if (parts[0] === 'face') {
        const feature = state.faceFeatures.find((item) => item.key === parts[1]);
        if (feature) feature.value = value;
        throttle(key, () => post('setFaceFeature', { key: parts[1], value }));
    } else if (parts[0] === 'overlay') {
        const overlay = getOverlay(parts[1]);
        if (overlay) overlay.opacity = value;
        throttle(key, async () => {
            const result = await post('setOverlay', { key: parts[1], opacity: value });
            if (result.ok && overlay) Object.assign(overlay, result.overlay);
        });
    }
}

function bindEditorControls() {
    content.querySelectorAll('[data-stepper] button').forEach((button) => {
        button.addEventListener('click', async () => {
            const stepperEl = button.closest('[data-stepper]');
            await adjustStepper(stepperEl.dataset.stepper, Number(button.dataset.step));
        });
    });

    content.querySelectorAll('[data-range]').forEach((input) => {
        input.addEventListener('input', () => handleRange(input));
        input.addEventListener('change', () => handleRange(input));
    });

    content.querySelectorAll('[data-camera-preset]').forEach((card) => {
        card.addEventListener('mouseenter', () => {
            post('cameraPreset', { preset: card.dataset.cameraPreset });
            previewTitle.textContent = card.querySelector('.item-card-head strong')?.textContent || 'Preview';
        });
    });
}

async function saveAppearance() {
    if (busy) return;
    busy = true;
    saveButton.disabled = true;
    savingOverlay.classList.remove('is-hidden');
    try {
        const result = await post('saveAppearance');
        if (!result.ok) {
            busy = false;
            saveButton.disabled = false;
            savingOverlay.classList.add('is-hidden');
            showToast(result.error || 'Unable to save appearance.');
        }
    } catch (error) {
        busy = false;
        saveButton.disabled = false;
        savingOverlay.classList.add('is-hidden');
        showToast('Unable to save appearance.');
    }
}

async function resetAppearance() {
    if (busy) return;
    busy = true;
    resetButton.disabled = true;
    const result = await post('resetAppearance');
    busy = false;
    resetButton.disabled = false;
    if (!result.ok || !result.state) {
        showToast('Unable to reset appearance.');
        return;
    }
    state = result.state;
    activeCategory = 'heritage';
    genderLabel.textContent = String(state.gender || '—').toUpperCase();
    renderNav();
    renderEditor();
    previewTitle.textContent = 'Face';
    await post('cameraPreset', { preset: 'head' });
}

saveButton.addEventListener('click', saveAppearance);
resetButton.addEventListener('click', resetAppearance);

document.querySelectorAll('[data-camera]').forEach((button) => {
    button.addEventListener('click', () => post('cameraControl', { action: button.dataset.camera }));
});

window.addEventListener('keydown', (event) => {
    if (app.classList.contains('is-hidden')) return;
    if (event.key === 'ArrowLeft') post('cameraControl', { action: 'left' });
    if (event.key === 'ArrowRight') post('cameraControl', { action: 'right' });
    if (event.key === 'Escape') showToast('Finish and save your appearance to continue.');
});

window.addEventListener('message', async (event) => {
    const data = event.data || {};
    if (data.action === 'hide') {
        app.classList.add('is-hidden');
        savingOverlay.classList.add('is-hidden');
        busy = false;
        return;
    }

    if (data.action !== 'open' || !data.state) return;

    state = data.state;
    activeCategory = 'heritage';
    busy = false;
    saveButton.disabled = false;
    savingOverlay.classList.add('is-hidden');
    document.getElementById('brand-name').textContent = data.brand || 'SOUTHVALE';
    document.getElementById('brand-suffix').textContent = data.suffix || 'ROLEPLAY';
    genderLabel.textContent = String(state.gender || '—').toUpperCase();
    renderNav();
    renderEditor();
    previewTitle.textContent = 'Face';
    app.classList.remove('is-hidden');
    await post('cameraPreset', { preset: 'head' });
});

post('ready').catch(() => {});
