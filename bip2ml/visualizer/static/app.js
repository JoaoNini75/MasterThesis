import { getAstJson } from "./requests.js";

const svg_style = `
    .ast-node { 
        cursor: pointer;
    }

    .ast-circle {
        fill: #ffffff; 
        stroke: #333333; 
        stroke-width: 2px; 
    }

    .name { 
        font-family: Arial, Helvetica, sans-serif; 
        font-size: 18px; 
        fill: #ffffff; 
    }
    
    line { 
        stroke: #333333;
        stroke-width: 2;
    }

    .ast-node .label-box rect {
        rx: 8;
        ry: 8;
        fill: rgba(255, 255, 255, 0.04);
        stroke: transparent;
    }

    .ast-node .label-box text {
        font-size: 14px;
        fill: #dbe9f5;
        pointer-events: none;
        text-anchor: start;
        dominant-baseline: middle;
    }

    text {
        fill: #252525ff;
    }
`;

const minZoom = 0.1;
const maxZoom = 100;
let isDarkMode = true;

const svgBipLang = document.getElementById("svgBipLang");
const getSVGBipLang = document.getElementById("getSVGBipLang");
const getPNGBipLang = document.getElementById("getPNGBipLang");
const copyBipLangJSON = document.getElementById("copyBipLangJSON");

const svgOCaml = document.getElementById("svgOCaml");
const getSVGOCaml = document.getElementById("getSVGOCaml");
const getPNGOCaml = document.getElementById("getPNGOCaml");
const copyOCamlJSON = document.getElementById("copyOCamlJSON");


getSVGBipLang.addEventListener("click", () => { downloadSVG("biplang") });
getPNGBipLang.addEventListener("click", () => { downloadPNG("biplang") });
copyBipLangJSON.addEventListener("click", () => { downloadJson("biplang") });

getSVGOCaml.addEventListener("click", () => { downloadSVG("ocaml") });
getPNGOCaml.addEventListener("click", () => { downloadPNG("ocaml") });
copyOCamlJSON.addEventListener("click", () => { downloadJson("ocaml") });


// --- Editor helper (line numbers + sync scroll) ---
export function updateLineNumbers(ta, ln) {
    const lines = Math.max(1, ta.value.split('\n').length);
    ln.textContent = Array.from({ length: lines }, (_, i) => i + 1).join('\n');
}

function manageEditor(textareaId, lnId, copyBtn) {
    const ta = document.getElementById(textareaId);
    const ln = document.getElementById(lnId);
    if (!ta || !ln) return;

    ta.addEventListener('scroll', () => { ln.scrollTop = ta.scrollTop; });
    ta.addEventListener('input', () => { updateLineNumbers(ta, ln) });
    updateLineNumbers(ta, ln);

    if (copyBtn) {
        copyBtn.addEventListener('click', () => {
            navigator.clipboard.writeText(ta.value);
        });
    }

    new ResizeObserver(() => { updateLineNumbers(ta, ln) }).observe(ta);
    return { textarea: ta, lineNumbers: ln };
}

const edA = manageEditor('taA', 'lnA', document.querySelector('#copyBipLang'));
const edB = manageEditor('taB', 'lnB', document.querySelector('#copyOCaml'));


// Tab handling
document.querySelectorAll('textarea.code').forEach(ta => {
    ta.addEventListener('keydown', function (e) {
        if (e.key === 'Tab') {
            e.preventDefault();
            const start = this.selectionStart;
            const end = this.selectionEnd;
            const value = this.value;
            this.value = value.substring(0, start) + '	' + value.substring(end);
            this.selectionStart = this.selectionEnd = start + 1;
            this.dispatchEvent(new Event('input'));
        }
    });
});

// --- Zoomable containers setup ---
function setupZoom(target) {
    const stage = document.getElementById(target + '-stage');
    const label = document.getElementById(target + '-label');
    const scrollWrap = document.getElementById(target + '-scroll');
    let zoom = 1;

    function apply() {
        stage.style.transform = `scale(${zoom})`;
        label.textContent = Math.round(zoom * 100) + '%';
    }

    function setZoom(z) {
        zoom = Math.max(minZoom, Math.min(maxZoom, z));
        apply();
    }

    document.querySelectorAll(`button[data-target="${target}"]`).forEach(btn => {
        btn.addEventListener('click', () => {
            const op = btn.getAttribute('data-zoom');
            if (op === '+') setZoom(zoom + 0.1);
            else if (op === '-') setZoom(zoom - 0.1);
            else if (op === 'reset') setZoom(1);
        });
    });

    scrollWrap.addEventListener('wheel', (e) => {
        if (e.ctrlKey) {
            e.preventDefault();
            const delta = e.deltaY < 0 ? 0.1 : - 0.1;
            setZoom(zoom + delta);
        }
    }, { passive: false });

    let lastTap = 0;
    scrollWrap.addEventListener('touchend', (e) => {
        const now = Date.now();
        if (now - lastTap < 300) { setZoom(1); }
        lastTap = now;
    });

    apply();
    return { setZoom };
}

const z1 = setupZoom('zoom1');
const z2 = setupZoom('zoom2');

// expose for debugging
window.__panels = { edA, edB, z1, z2 };


function downloadSVG(name) {
    if (getAstJson(name) === undefined) {
        alert("No SVG is available for download. Please use the transpile feature.")
        return;
    }

    const filename = name + "_ast.svg";
    const xml_header = '<?xml version="1.0" encoding="utf-8"?>';
    const svg = "biplang" ? svgBipLang : svgOCaml;
    const clone = svg.cloneNode(true);

    clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");
    clone.setAttribute("xmlns:xlink", "http://www.w3.org/1999/xlink");

    const style = document.createElementNS("http://www.w3.org/2000/svg", "style");
    style.textContent = svg_style;

    if (clone.firstChild)
        clone.insertBefore(style, clone.firstChild);
    else
        clone.appendChild(style);

    // serialize the clone to a string
    const serializer = new XMLSerializer();
    let svg_string = serializer.serializeToString(clone);

    // Fix for some browsers that drop the xmlns when serializing (defensive)
    if (!svg_string.includes('xmlns="http://www.w3.org/2000/svg"')) {
        svg_string = svg_string.replace(
            /^<svg/,
            '<svg xmlns="http://www.w3.org/2000/svg"'
        );
    }

    // add XML header and download
    const content = xml_header + svg_string;
    downloadFile(content, filename, "image/svg+xml");
}

function downloadPNG(name, scale = 1, background = null) {
    if (getAstJson(name) === undefined) {
        alert("No PNG is available for download. Please use the transpile feature.")
        return;
    }

    const svg = "biplang" ? svgBipLang : svgOCaml;
    const filename = name + "_ast.png";
    const xmlHeader = '<?xml version="1.0" encoding="utf-8"?>\n';

    // clone the SVG
    const clone = svg.cloneNode(true);

    // ensure namespace and inject style exactly as used in the SVG file
    clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");
    clone.setAttribute("xmlns:xlink", "http://www.w3.org/1999/xlink");

    const style = document.createElementNS("http://www.w3.org/2000/svg", "style");
    style.textContent = svg_style;

    if (clone.firstChild)
        clone.insertBefore(style, clone.firstChild);
    else
        clone.appendChild(style);

    // compute width/height from attributes or viewBox
    function parseNum(v) {
        if (!v)
            return null;
        return parseFloat(String(v).replace(/px$/, ""));
    }

    let width = parseNum(clone.getAttribute("width"));
    let height = parseNum(clone.getAttribute("height"));
    const viewBox = clone.getAttribute("viewBox");

    if ((!width || !height) && viewBox) {
        // viewBox = "minX minY width height"
        const vb = viewBox.trim().split(/\s+|,/).map(parseFloat);
        if (vb.length === 4) {
            width = vb[2];
            height = vb[3];
        }
    }

    // fallback if still unknown
    if (!width || !height) {
        width = 800;
        height = 600;
    }

    // apply scale (for higher DPI)
    const outW = Math.round(width * scale);
    const outH = Math.round(height * scale);

    // serialize the clone to an SVG string
    const serializer = new XMLSerializer();
    let svgString = serializer.serializeToString(clone);

    // ensure xmlns present (defensive)
    if (!svgString.includes('xmlns="http://www.w3.org/2000/svg"'))
        svgString = svgString.replace(/^<svg/, '<svg xmlns="http://www.w3.org/2000/svg"');

    const fullSvg = xmlHeader + svgString;
    // create an image from the SVG string (use blob URL) and draw to canvas
    createImage(filename, outW, outH, fullSvg, background);
}

function createImage(filename, outW, outH, fullSvg, background) {
    const svgBlob = new Blob([fullSvg], { type: "image/svg+xml;charset=utf-8" });
    const url = URL.createObjectURL(svgBlob);

    const img = new Image();
    // For SVG data from a blob URL crossOrigin generally isn't needed, but setting it can help with some setups
    img.crossOrigin = "anonymous";

    img.onload = () => {
        try {
            const canvas = document.createElement("canvas");
            canvas.width = outW;
            canvas.height = outH;
            const ctx = canvas.getContext("2d");

            // optional background (fill before drawing the SVG) - pass null for transparent
            if (background) {
                ctx.fillStyle = background;
                ctx.fillRect(0, 0, outW, outH);
            } else {
                // clear to transparent
                ctx.clearRect(0, 0, outW, outH);
            }

            // draw the SVG image scaled to the canvas size
            ctx.drawImage(img, 0, 0, outW, outH);

            // convert canvas to blob (PNG) and download
            canvas.toBlob((blob) => {
                if (!blob) {
                    console.error("Failed to produce PNG blob.");
                    URL.revokeObjectURL(url);
                    return;
                }
                const blobUrl = URL.createObjectURL(blob);
                const a = document.createElement("a");
                a.href = blobUrl;
                a.download = filename;
                document.body.appendChild(a);
                a.click();
                a.remove();
                URL.revokeObjectURL(blobUrl);
                URL.revokeObjectURL(url);
            }, "image/png");
        } catch (err) {
            console.error("Error drawing SVG to canvas:", err);
            URL.revokeObjectURL(url);
        }
    };

    img.onerror = (e) => {
        console.error("Failed to load SVG image for PNG conversion.", e);
        URL.revokeObjectURL(url);
    };

    img.src = url;
}

function downloadJson(name) {
    const ast_json = getAstJson(name);

    if (ast_json === undefined) {
        alert("No JSON is available for download. Please use the transpile feature.")
        return;
    }

    const pretty_ast_json = prettifyJson(ast_json);
    const filename = name + "_ast.json";
    downloadFile(pretty_ast_json, filename, 'application/json');
}

function prettifyJson(input) {
    const indent_space = 4;

    if (typeof input === 'string') {
        try {
            // parse string then re-stringify with indentation
            return JSON.stringify(JSON.parse(input), null, indent_space);
        } catch (err) {
            // not valid JSON string — fall back to returning original string
            return input;
        }
    }

    // input is an object/array — stringify with indentation
    return JSON.stringify(input, null, indent_space);
}

function downloadFile(content, filename, media_type) {
    const blob = new Blob([content], { type: media_type });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);  // needed for Firefox
    a.click();

    // cleanup
    a.remove();
    URL.revokeObjectURL(url);
}

function changeStyleProp(name, color) {
    document.documentElement.style.setProperty(name, color);
}

function getStyleProp(name) {
    return document.documentElement.style.getPropertyValue(name);
}

function changeColorMode() {
    isDarkMode = !isDarkMode;
    localStorage.setItem("isDarkMode", isDarkMode);

    changeStyleProp("--page-bg", isDarkMode ? "#05060a" : "#dbe9f5");
    changeStyleProp("--panel-bg", isDarkMode ? "#081019" : "#fdfeffff");
    changeStyleProp("--panel-edge", isDarkMode ? "#ffffff08" : "#adadadff");
    changeStyleProp("--muted", isDarkMode ? "#9aa6b3" : "#6b7076ff");
    changeStyleProp("--text", isDarkMode ? "#dbe9f5" : "#1d1d1dff");
    changeStyleProp("--outline", isDarkMode ? "#c4c4c4" : "#1d1d1dff");

    const textColor = getStyleProp("--text");

    // update ocaml code color
    document.getElementById("taB").style.color = textColor;

    // update trees' statistics
    const ast_info_list = document.querySelectorAll('.ast-info');
    ast_info_list.forEach(el => {
        el.style.fill = textColor;
    });
}

document.addEventListener('keyup', (e) => {
    const target = e.target;
    const isTypingField =
        target instanceof HTMLInputElement ||
        target instanceof HTMLTextAreaElement ||
        target.isContentEditable;

    if (isTypingField) return;

    // Fire on Ctrl+Q or Command+Q
    if ((e.ctrlKey || e.metaKey) && e.key && e.key.toLowerCase() === 'q') {
        e.preventDefault(); // optional
        changeColorMode();
    }
});

function initColorMode() {
    if (localStorage.getItem("isDarkMode") == "false")
        changeColorMode();
}

initColorMode();
