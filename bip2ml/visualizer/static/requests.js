import { updateLineNumbers } from "./app.js";
import { generateAST, cleanSVGs } from "./displayASTs.js";

const elems = {
    input: document.getElementById('taA'),
    run: document.getElementById('run'),
    output: document.getElementById('taB'),
    linesB: document.getElementById('lnB')
};

let bip_ast_json;
let ocaml_ast_json;

async function transpile() {
    const biplang_code = elems.input.value || "";
    elems.output.textContent = 'Sending...';
    elems.run.disabled = true;

    try {
        const res = await fetch('/run', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ biplang_code })
        });

        let data = await res.json();
        console.log(data);
        let { ocaml_code, bip_ast, ocaml_ast, error_msg } = data;

        if (error_msg != "") {
            elems.output.textContent = error_msg;
            elems.output.style.color = "red";
            cleanSVGs();
            return;
        }

        bip_ast_json = bip_ast;
        ocaml_ast_json = ocaml_ast;

        bip_ast = JSON.parse(bip_ast);
        ocaml_ast = JSON.parse(ocaml_ast);

        elems.output.textContent = ocaml_code;

        const textColor = getComputedStyle(document.documentElement).getPropertyValue('--text');
        elems.output.style.color = textColor;

        generateAST(bip_ast, "svgBipLang");
        generateAST(ocaml_ast, "svgOCaml");

        updateLineNumbers(elems.output, elems.linesB);
        if (!res.ok)
            console.log('Server returned ' + res.status + '\n\n' + elems.output.textContent);

    } finally {
        elems.run.disabled = false;
    }
}

elems.run.addEventListener('click', transpile);

export function getAstJson(name) {
    return name == "biplang" ? bip_ast_json : ocaml_ast_json;
}
