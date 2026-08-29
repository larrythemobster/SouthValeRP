const resource = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'southvale_mdt';

async function callNui(name, data = {}) {
    const resp = await fetch(`https://${resource}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    });
    return resp.json().catch(() => null);
}

const app = document.getElementById('app');

function switchTab(tab) {
    document.querySelectorAll('nav button').forEach((btn) => btn.classList.toggle('active', btn.dataset.tab === tab));
    document.querySelectorAll('.tab').forEach((section) => section.classList.toggle('active', section.id === `tab-${tab}`));
}

document.querySelectorAll('nav button').forEach((btn) => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

document.getElementById('closeBtn').addEventListener('click', () => {
    callNui('close');
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') callNui('close');
});

function renderCitizens(rows) {
    const body = document.getElementById('citizenResults');
    body.innerHTML = '';
    if (!rows || rows.length === 0) {
        body.innerHTML = '<tr><td colspan="4" class="empty">No results</td></tr>';
        return;
    }
    for (const row of rows) {
        const tr = document.createElement('tr');
        const fullName = [row.firstname, row.lastname].filter(Boolean).join(' ') || row.name;
        tr.innerHTML = `
            <td>${fullName}</td>
            <td>${row.citizenid}</td>
            <td>${row.phone || '—'}</td>
            <td><span class="badge ${row.hasRecord ? 'record' : 'clean'}">${row.hasRecord ? 'Has Record' : 'Clean'}</span></td>
        `;
        body.appendChild(tr);
    }
}

function renderVehicles(rows) {
    const body = document.getElementById('vehicleResults');
    body.innerHTML = '';
    if (!rows || rows.length === 0) {
        body.innerHTML = '<tr><td colspan="4" class="empty">No results</td></tr>';
        return;
    }
    for (const row of rows) {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${row.fakeplate || row.plate}</td>
            <td>${row.model}</td>
            <td>${row.ownerName || 'Unknown'}</td>
            <td><span class="badge ${row.impounded ? 'impounded' : 'ok'}">${row.impounded ? 'Impounded' : 'Active'}</span></td>
        `;
        body.appendChild(tr);
    }
}

function renderIncidents(rows) {
    const list = document.getElementById('incidentList');
    list.innerHTML = '';
    if (!rows || rows.length === 0) {
        list.innerHTML = '<div class="empty">No incidents logged</div>';
        return;
    }
    for (const row of rows) {
        const card = document.createElement('div');
        card.className = 'incident-card';
        const citizens = (row.citizens || []).map((c) => c.citizenid || c).join(', ');
        card.innerHTML = `
            <button class="delete" data-id="${row.id}">Delete</button>
            <h3>${row.title}</h3>
            <div class="meta">${row.officer_name} • ${new Date(row.created_at).toLocaleString()}${citizens ? ' • ' + citizens : ''}</div>
            <p>${row.details}</p>
        `;
        card.querySelector('.delete').addEventListener('click', async () => {
            await callNui('deleteIncident', { id: row.id });
            loadIncidents();
        });
        list.appendChild(card);
    }
}

async function loadIncidents() {
    renderIncidents(await callNui('getIncidents'));
}

document.getElementById('citizenSearchBtn').addEventListener('click', async () => {
    const query = document.getElementById('citizenQuery').value.trim();
    renderCitizens(await callNui('searchCitizens', { query }));
});

document.getElementById('vehicleSearchBtn').addEventListener('click', async () => {
    const query = document.getElementById('vehicleQuery').value.trim();
    renderVehicles(await callNui('searchVehicles', { query }));
});

document.getElementById('incidentCreateBtn').addEventListener('click', async () => {
    const title = document.getElementById('incidentTitle').value.trim();
    const details = document.getElementById('incidentDetails').value.trim();
    const citizensRaw = document.getElementById('incidentCitizens').value.trim();
    if (!title || !details) return;

    const citizens = citizensRaw ? citizensRaw.split(',').map((c) => ({ citizenid: c.trim() })).filter((c) => c.citizenid) : [];
    await callNui('createIncident', { title, details, citizens });

    document.getElementById('incidentTitle').value = '';
    document.getElementById('incidentDetails').value = '';
    document.getElementById('incidentCitizens').value = '';
    loadIncidents();
});

window.addEventListener('message', (event) => {
    const { action } = event.data;
    if (action === 'open') {
        app.classList.remove('hidden');
        loadIncidents();
    } else if (action === 'close') {
        app.classList.add('hidden');
    } else if (action === 'incidentsChanged') {
        loadIncidents();
    }
});
