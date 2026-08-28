import { getHandoverData } from './util/handover.js';

const handoverData = getHandoverData();
const storyImage = document.getElementById('story-image');
const storyDots = document.getElementById('story-dots');
const loadPercentage = document.getElementById('load-percentage');
const loadingTitle = document.getElementById('loading-title');
const loadingSubtitle = document.getElementById('loading-subtitle');
const shortcutButton = document.getElementById('shortcut-button');
const shortcutPanel = document.getElementById('shortcut-panel');
const shortcutClose = document.getElementById('shortcut-close');

const images = handoverData?.paths?.images ?? [];
let storyIndex = images.length > 1 ? 1 : 0;
let storyTimer = null;

function setStoryImage(index) {
    if (!storyImage) return;

    if (!images.length) {
        storyImage.removeAttribute('src');
        storyImage.style.background = 'linear-gradient(145deg, #062654, #020914)';
        return;
    }

    storyIndex = ((index % images.length) + images.length) % images.length;
    storyImage.style.opacity = '0.45';
    window.setTimeout(() => {
        storyImage.src = images[storyIndex];
        storyImage.style.opacity = '1';
        storyImage.style.transform = 'scale(1.035)';
        window.setTimeout(() => {
            storyImage.style.transform = 'scale(1.015)';
        }, 100);
    }, 180);

    storyDots?.querySelectorAll('span').forEach((dot, dotIndex) => {
        dot.classList.toggle('active', dotIndex === storyIndex % Math.min(Math.max(images.length, 1), 6));
    });
}

function setupStoryCarousel() {
    if (!storyDots) return;

    const count = Math.min(Math.max(images.length, 1), 6);
    storyDots.replaceChildren();
    for (let i = 0; i < count; i += 1) {
        const dot = document.createElement('span');
        dot.classList.toggle('active', i === storyIndex);
        storyDots.appendChild(dot);
    }

    setStoryImage(storyIndex);
    if (images.length > 1) {
        storyTimer = window.setInterval(() => {
            setStoryImage(storyIndex + 1);
        }, Math.max(handoverData.config.imageRate ?? 7500, 4500));
    }
}

function setShortcuts(open) {
    if (!shortcutPanel) return;
    shortcutPanel.classList.toggle('open', open);
    shortcutPanel.setAttribute('aria-hidden', open ? 'false' : 'true');
}

shortcutButton?.addEventListener('click', () => setShortcuts(true));
shortcutClose?.addEventListener('click', () => setShortcuts(false));
shortcutPanel?.addEventListener('mousedown', (event) => {
    if (event.target === shortcutPanel) setShortcuts(false);
});
document.addEventListener('keydown', (event) => {
    if (event.code === 'Escape') setShortcuts(false);
});

const phaseCopy = {
    startDataFileEntries: ['Loading Southvale assets', 'Preparing vehicles, interiors and world data...'],
    onDataFileEntry: ['Loading Southvale assets', 'Streaming city content...'],
    performMapLoadFunction: ['Building your world', 'Preparing Los Santos...'],
    startInitFunction: ['Starting server systems', 'Connecting gameplay resources...'],
    startInitFunctionOrder: ['Starting server systems', 'Connecting gameplay resources...'],
    initFunctionInvoking: ['Starting server systems', 'Almost ready to enter Southvale...'],
    endInitFunction: ['Final checks', 'Synchronizing your session...'],
};

window.addEventListener('message', ({ data }) => {
    if (!data || typeof data !== 'object') return;

    if (data.eventName === 'loadProgress') {
        const fraction = Math.min(Math.max(Number(data.loadFraction) || 0, 0), 1);
        const percent = Math.round(fraction * 100);
        if (loadPercentage) loadPercentage.textContent = `${percent}%`;

        if (fraction >= 1) {
            if (loadingTitle) loadingTitle.textContent = 'Welcome to Southvale';
            if (loadingSubtitle) loadingSubtitle.textContent = 'Finishing your connection...';
        }
        return;
    }

    const copy = phaseCopy[data.eventName];
    if (copy) {
        if (loadingTitle) loadingTitle.textContent = copy[0];
        if (loadingSubtitle) loadingSubtitle.textContent = copy[1];
    }
});

window.addEventListener('beforeunload', () => {
    if (storyTimer !== null) window.clearInterval(storyTimer);
});

setupStoryCarousel();
