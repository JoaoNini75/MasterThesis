from flask import Flask, send_from_directory, request, jsonify
import subprocess
import os


PORT = 5000

INPUT_FILE = "web_server.bip"
OUTPUT_FILE = "web_server.ml"
BIP_JSON_FILE = "bip_ast.json"
OCAML_JSON_FILE = "ml_ast.json"

app = Flask(__name__, static_folder="static")


@app.route('/<path:filename>') # Explicit static file handler
def serve_static_files(filename):
    return send_from_directory(app.static_folder, filename)

@app.route("/")
def index():
    return send_from_directory("static", "index.html")

@app.route("/run", methods=["POST"])
def run_bip():
    data = request.get_json()
    biplang_code = data.get("biplang_code", "")

    # Write input
    with open(f"../src/{INPUT_FILE}", "w", encoding="utf-8") as f:
        f.write(biplang_code)

    # Compile bip2ml
    subprocess.run(["bash", "-c", 
                    "cd ../src && dune build biplang.exe"],
                    capture_output=True, text=True)
    
    # Run bip2ml with 'print-asts' flag
    run_output = subprocess.run(["bash", "-c",
                    f"cd ../src && dune exec -- ./biplang.exe {INPUT_FILE} {OUTPUT_FILE} --print-asts"],
                    capture_output=True, text=True)
    
    print(run_output)

    # Read OCaml code, BipLang AST and OCaml AST files and return as JSON
    return jsonify({
        "ocaml_code": get_file_content(OUTPUT_FILE),
        "bip_ast": get_file_content(BIP_JSON_FILE),
        "ocaml_ast": get_file_content(OCAML_JSON_FILE),
        "error_msg": run_output.stderr
    })


def get_file_content(filename, dir = "../src/"):
    path = dir + filename
    content = f"ERROR: {path} file not found"

    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

    return content


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
