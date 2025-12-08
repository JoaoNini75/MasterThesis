const grid = document.getElementById('mainGrid');
const vSplit = document.getElementById('vSplit');
const hSplit = document.getElementById('hSplit');
const center = document.getElementById('centerHandle');
const splitSize =
    parseInt(getComputedStyle(document.documentElement).getPropertyValue('--split-size'))
    || 10;


loadPanelsDimensions();

function loadPanelsDimensions() {
    loadDimension("--col-left", localStorage.getItem("--col-left"));
    loadDimension("--col-right", localStorage.getItem("--col-right"));
    loadDimension("--row-top", localStorage.getItem("--row-top"));
    loadDimension("--row-bottom", localStorage.getItem("--row-bottom"));
}

function loadDimension(name, value) {
    if (value == null) return;
    grid.style.setProperty(name, value + 'px');
}

function savePanelsDimensions(names, values) {
    for (let i = 0; i < names.length; i++)
        localStorage.setItem(names[i], values[i]);
}

function colsInPx() {
    const rect = grid.getBoundingClientRect();
    const template = window.getComputedStyle(grid).gridTemplateColumns.split(' ');
    const leftStr = template[0];
    const rightStr = template[2];

    function toPx(str) {
        if (str.endsWith('%')) return rect.width * parseFloat(str) / 100;
        if (str.endsWith('px')) return parseFloat(str);
        if (str.endsWith('fr'))
            // distribute remaining space proportionally; for 1fr/1fr fallback to half
            return rect.width / 2;

        return rect.width / 2;
    }

    return { left: toPx(leftStr), right: toPx(rightStr), total: rect.width };
}

// vertical drag
vSplit.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    vSplit.setPointerCapture(e.pointerId);

    const rect = grid.getBoundingClientRect();
    const startX = e.clientX;
    const startLeft = colsInPx().left;
    const min = 120; // min panel width
    const max = rect.width - min - splitSize;

    function onMove(ev) {
        const dx = ev.clientX - startX;
        let newLeft = Math.min(max, Math.max(min, startLeft + dx));
        let newRight = rect.width - newLeft - splitSize;
        grid.style.setProperty('--col-left', newLeft + 'px');
        grid.style.setProperty('--col-right', newRight + 'px');
        savePanelsDimensions(['--col-left', '--col-right'], [newLeft, newRight]);
    }

    function onUp() {
        vSplit.releasePointerCapture(e.pointerId);
        window.removeEventListener('pointermove', onMove);
        window.removeEventListener('pointerup', onUp);
    }

    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerup', onUp);
});

// horizontal drag
hSplit.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    hSplit.setPointerCapture(e.pointerId);

    const rect = grid.getBoundingClientRect();
    const startY = e.clientY;
    const topStart = grid.querySelector('#editorA-panel').getBoundingClientRect().height;
    const min = 80;
    const max = rect.height - min - splitSize;

    function onMove(ev) {
        const dy = ev.clientY - startY;
        let newTop = Math.min(max, Math.max(min, topStart + dy));
        let newBottom = rect.height - newTop - splitSize;
        grid.style.setProperty('--row-top', newTop + 'px');
        grid.style.setProperty('--row-bottom', newBottom + 'px');
        savePanelsDimensions(['--row-top', '--row-bottom'], [newTop, newBottom]);
    }

    function onUp() {
        hSplit.releasePointerCapture(e.pointerId);
        window.removeEventListener('pointermove', onMove);
        window.removeEventListener('pointerup', onUp);
    }

    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerup', onUp);
});

// center handle: drag both
center.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    center.setPointerCapture(e.pointerId);

    const rect = grid.getBoundingClientRect();
    const startX = e.clientX;
    const startY = e.clientY;
    const leftStart = colsInPx().left;
    const topStart = grid.querySelector('#editorA-panel').getBoundingClientRect().height;
    const min = 80;

    function onMove(ev) {
        const dx = ev.clientX - startX;
        const dy = ev.clientY - startY;
        let newLeft = Math.min(rect.width - min - splitSize, Math.max(min, leftStart + dx));
        let newTop = Math.min(rect.height - min - splitSize, Math.max(min, topStart + dy));
        let newRight = rect.width - newLeft - splitSize;
        let newBottom = rect.height - newTop - splitSize;
        grid.style.setProperty('--col-left', newLeft + 'px');
        grid.style.setProperty('--col-right', newRight + 'px');
        grid.style.setProperty('--row-top', newTop + 'px');
        grid.style.setProperty('--row-bottom', newBottom + 'px');
        savePanelsDimensions(['--col-left', '--col-right', '--row-top', '--row-bottom'],
            [newLeft, newRight, newTop, newBottom]);
    }

    function onUp() {
        center.releasePointerCapture(e.pointerId);
        window.removeEventListener('pointermove', onMove);
        window.removeEventListener('pointerup', onUp);
    }

    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerup', onUp);
});

// ensure initial pixel values are set on load/resize
function normalize() {
    const rect = grid.getBoundingClientRect();
    const styleCols = getComputedStyle(grid).gridTemplateColumns.split(' ');
    const styleRows = getComputedStyle(grid).gridTemplateRows.split(' ');

    if (styleCols[0].includes('%')) {
        const pct = parseFloat(styleCols[0]);
        grid.style.setProperty('--col-left', (rect.width * pct / 100) + 'px');
        grid.style.setProperty('--col-right', (rect.width * (100 - pct) / 100 - splitSize) + 'px');
    }

    if (styleRows[0].includes('%')) {
        const rp = parseFloat(styleRows[0]);
        grid.style.setProperty('--row-top', (rect.height * rp / 100) + 'px');
        grid.style.setProperty('--row-bottom', (rect.height * (100 - rp) / 100 - splitSize) + 'px');
    }
}

window.addEventListener('resize', normalize);
normalize();
