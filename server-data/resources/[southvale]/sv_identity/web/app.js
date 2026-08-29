const app = document.getElementById('app');
const characterView = document.getElementById('character-view');
const identityView = document.getElementById('identity-view');
const spawnView = document.getElementById('spawn-view');
const characterList = document.getElementById('character-list');
const characterDetail = document.getElementById('character-detail');
const spawnList = document.getElementById('spawn-list');
const deleteModal = document.getElementById('delete-modal');
const deleteCopy = document.getElementById('delete-copy');
const toast = document.getElementById('toast');
const form = document.getElementById('identity-form');
const formError = document.getElementById('form-error');
const nationalitySelect = document.getElementById('nationality-select');
const genderSelect = document.getElementById('gender');
const nationalityInput = document.getElementById('nationality-input');
const createSubmit = document.getElementById('create-submit');

let state = {
    slots: [],
    selectedSlot: null,
    deletionEnabled: false,
    deleteSlot: null,
    identitySlot: null,
    busy: false,
};

function resourceName() {
    return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'sv_identity';
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

function applyBrand(brand = {}) {
    document.getElementById('brand-name').textContent = brand.name || 'SOUTHVALE';
    document.getElementById('brand-suffix').textContent = brand.suffix || 'ROLEPLAY';
    document.getElementById('eyebrow').textContent = brand.eyebrow || 'CHARACTER ACCESS';
    if (brand.accent) document.documentElement.style.setProperty('--accent', brand.accent);
}

function showOnly(view) {
    characterView.classList.toggle('is-hidden', view !== 'characters');
    identityView.classList.toggle('is-hidden', view !== 'identity');
    spawnView.classList.toggle('is-hidden', view !== 'spawn');
    app.classList.remove('is-hidden');
}

function showToast(message) {
    if (!message) return;
    toast.textContent = message;
    toast.classList.remove('is-hidden');
    clearTimeout(showToast.timer);
    showToast.timer = setTimeout(() => toast.classList.add('is-hidden'), 3500);
}

function selectedCharacter() {
    return state.slots.find((slot) => slot.slot === state.selectedSlot) || null;
}

function renderCharacters() {
    characterList.innerHTML = state.slots.map((slot) => {
        const selected = slot.slot === state.selectedSlot ? ' is-selected' : '';
        if (slot.empty) {
            return `<button class="character-card empty${selected}" data-slot="${slot.slot}" type="button">
                <span class="slot">Slot ${slot.slot}</span>
                <strong>Create character</strong>
                <small>Start a new life in SouthVale.</small>
            </button>`;
        }

        return `<button class="character-card${selected}" data-slot="${slot.slot}" type="button">
            <span class="slot">Slot ${slot.slot}</span>
            <strong>${escapeHtml(slot.firstname)} ${escapeHtml(slot.lastname)}</strong>
            <small>${escapeHtml(slot.job)} · ${escapeHtml(slot.grade)}</small>
        </button>`;
    }).join('');

    characterList.querySelectorAll('.character-card').forEach((button) => {
        button.addEventListener('click', async () => {
            if (state.busy) return;
            const slot = Number(button.dataset.slot);
            state.selectedSlot = slot;
            renderCharacters();
            renderDetail();
            await post('selectCharacter', { slot });
        });
    });
}

function renderDetail() {
    const slot = selectedCharacter();
    if (!slot) {
        characterDetail.innerHTML = '<p class="muted">Select a character slot.</p>';
        return;
    }

    if (slot.empty) {
        characterDetail.innerHTML = `
            <div class="detail-name">
                <div><span>EMPTY SLOT ${slot.slot}</span><h2>New character</h2></div>
            </div>
            <p class="muted">Create a new identity using SouthVale's secure Qbox character flow.</p>
            <div class="actions">
                <button id="create-button" class="primary-button" type="button">Create character</button>
            </div>`;
        document.getElementById('create-button').addEventListener('click', () => openCreate(slot.slot));
        return;
    }

    characterDetail.innerHTML = `
        <div class="detail-name">
            <div><span>CHARACTER SLOT ${slot.slot}</span><h2>${escapeHtml(slot.firstname)} ${escapeHtml(slot.lastname)}</h2></div>
            <span>${escapeHtml(slot.gender)}</span>
        </div>
        <div class="stats">
            <div class="stat"><span>Date of birth</span><strong>${escapeHtml(slot.birthdate || 'Not set')}</strong></div>
            <div class="stat"><span>Nationality</span><strong>${escapeHtml(slot.nationality || 'Not set')}</strong></div>
            <div class="stat"><span>Occupation</span><strong>${escapeHtml(slot.job)}</strong></div>
            <div class="stat"><span>Position</span><strong>${escapeHtml(slot.grade)}</strong></div>
            <div class="stat"><span>Cash</span><strong>${escapeHtml(slot.cash)}</strong></div>
            <div class="stat"><span>Bank</span><strong>${escapeHtml(slot.bank)}</strong></div>
        </div>
        <div class="actions">
            ${state.deletionEnabled ? '<button id="delete-button" class="secondary-button" type="button">Delete</button>' : ''}
            <button id="play-button" class="primary-button" type="button">Play character</button>
        </div>`;

    document.getElementById('play-button').addEventListener('click', () => playCharacter(slot.slot));
    const deleteButton = document.getElementById('delete-button');
    if (deleteButton) deleteButton.addEventListener('click', () => openDelete(slot));
}

async function openCreate(slot) {
    if (state.busy) return;
    state.busy = true;
    const result = await post('openCreate', { slot });
    state.busy = false;
    if (!result.ok) showToast(result.error || 'Unable to open character creation.');
}

async function playCharacter(slot) {
    if (state.busy) return;
    state.busy = true;
    const result = await post('playCharacter', { slot });
    if (!result.ok) {
        state.busy = false;
        showToast(result.error || 'Unable to load that character.');
    }
}

function openDelete(slot) {
    state.deleteSlot = slot.slot;
    deleteCopy.textContent = `${slot.firstname} ${slot.lastname} will be permanently deleted. This cannot be undone.`;
    deleteModal.classList.remove('is-hidden');
    document.getElementById('delete-cancel').focus();
}

function closeDelete() {
    state.deleteSlot = null;
    deleteModal.classList.add('is-hidden');
}

function configureIdentity(data) {
    state.identitySlot = Number(data.slot);
    document.getElementById('slot-label').textContent = `Character slot ${state.identitySlot}`;
    document.getElementById('birthdate').min = data.dateMin || '';
    document.getElementById('birthdate').max = data.dateMax || '';
    document.getElementById('birthdate').value = data.dateMax || '';

    genderSelect.innerHTML = '<option value="" disabled selected>Select gender</option>' +
        (data.genders || []).map((item) => `<option value="${escapeHtml(item)}">${escapeHtml(item)}</option>`).join('');

    if (data.limitNationalities) {
        nationalitySelect.innerHTML = '<option value="" disabled selected>Select nationality</option>' +
            (data.nationalities || []).map((item) => `<option value="${escapeHtml(item)}">${escapeHtml(item)}</option>`).join('');
        nationalitySelect.classList.remove('is-hidden');
        nationalityInput.classList.add('is-hidden');
        nationalityInput.value = '';
    } else {
        nationalitySelect.classList.add('is-hidden');
        nationalityInput.classList.remove('is-hidden');
        nationalitySelect.value = '';
    }

    form.reset();
    document.getElementById('birthdate').value = data.dateMax || '';
    formError.textContent = '';
    createSubmit.disabled = false;
    state.busy = false;
}

function renderSpawns(spawns = []) {
    spawnList.innerHTML = spawns.map((spawn) => `
        <button class="spawn-card" data-id="${spawn.id}" type="button">
            <span class="slot">${escapeHtml(spawn.kind || 'arrival')}</span>
            <strong>${escapeHtml(spawn.label)}</strong>
            <small>${escapeHtml(spawn.description || '')}</small>
        </button>`).join('');

    spawnList.querySelectorAll('.spawn-card').forEach((button) => {
        button.addEventListener('mouseenter', () => {
            post('previewSpawn', { id: Number(button.dataset.id) });
        });
        button.addEventListener('click', async () => {
            if (state.busy) return;
            state.busy = true;
            button.classList.add('is-selected');
            post('previewSpawn', { id: Number(button.dataset.id) });
            const result = await post('chooseSpawn', { id: Number(button.dataset.id) });
            if (!result.ok) {
                state.busy = false;
                button.classList.remove('is-selected');
                showToast('Unable to use that spawn location.');
            }
        });
    });
}

form.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (state.busy) return;

    const firstname = document.getElementById('firstname').value.trim();
    const lastname = document.getElementById('lastname').value.trim();
    const birthdate = document.getElementById('birthdate').value;
    const gender = document.getElementById('gender').value;
    const nationality = nationalitySelect.classList.contains('is-hidden')
        ? nationalityInput.value.trim()
        : nationalitySelect.value;

    if (!firstname || !lastname || !birthdate || gender === '' || !nationality) {
        formError.textContent = 'Complete every required field.';
        return;
    }

    state.busy = true;
    createSubmit.disabled = true;
    formError.textContent = '';

    const result = await post('createCharacter', {
        firstname,
        lastname,
        birthdate,
        gender,
        nationality,
    });

    if (!result.ok) {
        state.busy = false;
        createSubmit.disabled = false;
        formError.textContent = result.error || 'Character creation failed.';
    }
});

document.getElementById('identity-back').addEventListener('click', async () => {
    if (state.busy) return;
    await post('cancelCreate');
});

document.getElementById('delete-cancel').addEventListener('click', closeDelete);
document.getElementById('delete-confirm').addEventListener('click', async () => {
    if (!state.deleteSlot || state.busy) return;
    state.busy = true;
    const result = await post('deleteCharacter', { slot: state.deleteSlot });
    state.busy = false;
    if (!result.ok) showToast(result.error || 'Character deletion failed.');
    closeDelete();
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !deleteModal.classList.contains('is-hidden')) closeDelete();
});

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'hide') {
        app.classList.add('is-hidden');
        state.busy = false;
        return;
    }

    applyBrand(data.brand);

    if (data.action === 'showCharacters') {
        state.slots = Array.isArray(data.slots) ? data.slots : [];
        state.selectedSlot = Number(data.selectedSlot) || state.slots[0]?.slot || null;
        state.deletionEnabled = Boolean(data.deletionEnabled);
        state.busy = false;
        renderCharacters();
        renderDetail();
        showOnly('characters');
        if (data.error) showToast(data.error);
    } else if (data.action === 'showIdentity') {
        configureIdentity(data);
        showOnly('identity');
        setTimeout(() => document.getElementById('firstname').focus(), 0);
    } else if (data.action === 'showSpawns') {
        state.busy = false;
        renderSpawns(Array.isArray(data.spawns) ? data.spawns : []);
        showOnly('spawn');
    }
});

post('ready').catch(() => {});
