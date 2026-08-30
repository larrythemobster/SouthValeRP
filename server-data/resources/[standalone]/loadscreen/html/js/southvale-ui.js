const percentage = document.getElementById('loading-percentage');
const loadingStatus = document.getElementById('loading-status');
const rotatingTip = document.getElementById('rotating-tip');
const logo = document.getElementById('logo');
const logoFallback = document.getElementById('logo-fallback');
const audioVolume = document.getElementById('audio-volume');
const audioGlyph = document.getElementById('audio-mute-glyph');

const tips = [
    'Keep scenes character-driven. The best stories come from choices, not wins.',
    'Your character should have goals, flaws, relationships, and something to lose.',
    'Police, EMS, businesses, careers, and crime all feed the same player-driven city.',
    'Value the scene in front of you. Good roleplay gives everyone something to work with.',
    'Join the Discord for rules, announcements, applications, support, and development updates.',
    'Actions have consequences. Plan your moves and give other players room to respond.',
];

const loadingStages = [
    [0.08, 'CONNECTING TO SOUTHVALE'],
    [0.24, 'VERIFYING CITY SESSION'],
    [0.48, 'STREAMING SOUTHVALE ASSETS'],
    [0.72, 'INITIALIZING CITY SYSTEMS'],
    [0.91, 'SYNCING PLAYER SERVICES'],
    [1.01, 'FINALIZING YOUR ARRIVAL'],
];

let tipIndex = 0;

function openExternal(url) {
    try {
        if (typeof window.invokeNative === 'function') {
            window.invokeNative('openUrl', url);
            return;
        }
    } catch (_) {
        // Browser preview fallback below.
    }

    window.open(url, '_blank', 'noopener,noreferrer');
}

document.querySelectorAll('[data-external-link]').forEach((link) => {
    link.addEventListener('click', (event) => {
        event.preventDefault();
        openExternal(link.href);
    });
});

window.addEventListener('message', ({ data }) => {
    if (data?.eventName === 'loadProgress') {
        const fraction = Math.max(0, Math.min(1, Number(data.loadFraction) || 0));
        const rounded = Math.round(fraction * 100);
        if (percentage) percentage.textContent = `${rounded}%`;

        const stage = loadingStages.find(([limit]) => fraction < limit);
        if (loadingStatus && stage) loadingStatus.textContent = stage[1];
    }

    if (data?.customEvent === 'finishedLoading') {
        if (percentage) percentage.textContent = '100%';
        if (loadingStatus) loadingStatus.textContent = 'CITY READY';
    }
});

if (rotatingTip) {
    setInterval(() => {
        rotatingTip.classList.add('tip-changing');
        setTimeout(() => {
            tipIndex = (tipIndex + 1) % tips.length;
            rotatingTip.textContent = tips[tipIndex];
            rotatingTip.classList.remove('tip-changing');
        }, 220);
    }, 6200);
}

if (logo && logoFallback) {
    const useImageLogo = () => {
        if (!logo.src || logo.style.display === 'none') return;
        logoFallback.style.display = 'none';
    };

    logo.addEventListener('load', useImageLogo);
    logo.addEventListener('error', () => {
        logo.style.display = 'none';
        logoFallback.style.display = '';
    });

    setTimeout(useImageLogo, 100);
}

function updateAudioGlyph() {
    if (!audioGlyph || !audioVolume) return;
    audioGlyph.textContent = Number(audioVolume.value) <= 0 ? '×' : '♪';
}

if (audioVolume) {
    audioVolume.addEventListener('input', updateAudioGlyph);
    setTimeout(updateAudioGlyph, 150);
}
