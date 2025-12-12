const SVG_NS = 'http://www.w3.org/2000/svg';
const node_radius = 64;
const default_margin = 100; // minimum distance between a node and the viewBox limit
const dist_nodes_h = 100; // horizontal distance between nodes (from center of node 1 to center of node 2)

// TODO: tornar variavel? para nao ter nodes pintados em cima de edges (acontece quando 1 node tem muitos filhos)
const dist_nodes_v = 230; // vertical distance between nodes (from center of node 1 to center of node 2)

const NodeCategory = Object.freeze({
    Type: "#a10500ff",
    Constructor: "#00920aff",
    Leaf: "#12009dff"
});

/* 
    Structure of the AST:

    node {
        type: string
        name: string
        value: string 
        children: node list
    }
*/

/**
 * Sets the category of the node given by the parameter.
 * 
 * @param {object} node - node of the AST
 */
function setNodeCategory(node) {
    if (node.type != "" && node.value != "")
        node.category = NodeCategory.Leaf;
    else if (node.name != "")
        node.category = NodeCategory.Constructor;
    else
        node.category = NodeCategory.Type;
}

/**
 * Receives an AST object and displays it on the panel given by the id.
 * 
 * @param {object} ast - the tree to be displayed
 * @param {string} id - identifier of the panel
 */
export function generateAST(ast, id) {
    const svg = document.getElementById(id);
    cleanSVG(id);
    const { tree_width, tree_height, tree_node_num } = getTreeInfo(ast);

    displayASTInfo(svg, tree_width, tree_height, tree_node_num, id);

    // TODO: display node info in a balloon when hovering or selected: category, type, name, value

    /*const nodes =*/ displayAST(svg, ast, tree_height);
}

export function cleanSVGs() {
    cleanSVG("svgBipLang");
    cleanSVG("svgOCaml");
}

function cleanSVG(id) {
    document.getElementById(id).innerHTML = "";
}

/**
 * Calculates the positions of all the nodes of the tree, and displays the
 * edges and the nodes. Edges should be displayed before nodes so there are no
 * lines on top of the circles.
 * 
 * @param {SVGElement} svg - the svg of the panel to display the tree on
 * @param {object} root - ast root node
 * @param {int} tree_height - the height of the AST
 * 
 * @returns {Array} positions - an array with all the nodes'
 * previous properties and additional ones: their X and Y coordinates,
 * and category
 */
function displayAST(svg, root, tree_height) {

    // 1. compute subtrees' widths
    computeWidth(root);

    function computeWidth(node) {
        const children = node.children || [];

        if (children.length === 0) {
            node.subtreeWidth = dist_nodes_h;
            return node.subtreeWidth;
        }

        let sum = 0;
        for (const c of children)
            sum += computeWidth(c);

        const gaps = (children.length - 1) * dist_nodes_h;
        node.subtreeWidth = Math.max(dist_nodes_h, sum + gaps);
        return node.subtreeWidth;
    }

    // 2. set svg dimensions
    const view_box_width = root.subtreeWidth + default_margin;
    const view_box_height = default_margin +
        (node_radius * 2) /* node diameter */ * tree_height +
        (dist_nodes_v - node_radius * 2)/* dist between nodes vertically */ * (tree_height - 1);

    svg.setAttribute("viewBox", `0 0 ${view_box_width} ${view_box_height}`);
    const rootX = view_box_width / 2;
    const rootY = default_margin;

    // 3. assign positions (center each node over its children's block)
    const positions = [];
    assign(root, rootX, rootY);

    function assign(node, x, y) {
        node.x = x;
        node.y = y;
        positions.push(node);

        const children = node.children || [];

        if (children.length === 0)
            return;

        const totalChildrenWidth =
            children.reduce((acc, c) => acc + c.subtreeWidth, 0) +
            Math.max(0, children.length - 1) * dist_nodes_h;

        let start = x - totalChildrenWidth / 2;

        for (const c of children) {
            const centerX = start + c.subtreeWidth / 2;
            const childX = centerX;
            const childY = y + dist_nodes_v;

            assign(c, childX, childY);
            start += c.subtreeWidth + dist_nodes_h;
            displayEdge(svg, x, y, childX, childY);
        }
    }

    // 4. display nodes
    for (let i = 0; i < positions.length; i++) {
        const node = positions[i];
        let name, label = "";
        setNodeCategory(node);

        switch (node.category) {
            case NodeCategory.Leaf:
                name = node.type;
                label = node.value;
                break;
            case NodeCategory.Constructor:
                name = node.name;
                break;
            case NodeCategory.Type:
                name = node.type;
                break;
        }

        displayNode(svg, node.x, node.y, name, label, node.category);
    }

    return positions;
}

/**
 * Calculates the width, height and number of nodes of the AST.  
 * 
 * @param {object} root - ast root node
 * @returns {object} { tree_width, tree_height, tree_node_num }
 */
function getTreeInfo(root) {
    const levels = new Map(); // key: level, value: num of nodes
    levels.set(0, 1);

    let maxWidth = 1;
    let level = 1;
    traverse(root, level);

    function traverse(node, level) {
        const children_num = node.children.length;
        let level_curr_width = children_num;

        if (levels.has(level))
            level_curr_width += levels.get(level);

        levels.set(level, level_curr_width);
        if (level_curr_width > maxWidth)
            maxWidth = level_curr_width;

        level++;
        for (let i = 0; i < children_num; i++)
            traverse(node.children[i], level);
    }

    //console.log(levels);
    let node_num = 0;
    for (const value of levels.values())
        node_num += value;

    return {
        tree_width: maxWidth,
        tree_height: levels.size - 1, /* because last level is always empty */
        tree_node_num: node_num
    };
}

/**
 * Display meta info of an AST: height, width and number of nodes.
 * 
 * @param {SVGElement} svg - The SVG root element to append to.
 * @param {int} tree_width - the width of the tree
 * @param {int} tree_height - the height of the tree
 * @param {int} tree_node_num - the total number of nodes in the tree
 * @param {string} id - the id of the svg
 */
function displayASTInfo(svg, tree_width, tree_height, tree_node_num, id) {
    const info = document.createElementNS(SVG_NS, 'text');
    const x = 10;
    const y = 10;
    const lineHeight = 1.2; // em units
    const fontSize = tree_width * 5;
    const textColor = getComputedStyle(document.documentElement).getPropertyValue('--text');

    info.classList.add('ast-info');
    info.setAttribute('x', x);
    info.setAttribute('y', y);
    info.setAttribute('dominant-baseline', 'hanging');
    info.setAttribute('font-size', fontSize);
    info.style.pointerEvents = 'none';
    info.style.fill = textColor;

    const lines = [
        `Height: ${tree_height}`,
        `Width: ${tree_width}`,
        `Nodes: ${tree_node_num}`
    ];

    lines.forEach((line, i) => {
        const tspan = document.createElementNS(SVG_NS, 'tspan');

        // first line uses the parent x/y; subsequent lines use dy to move down
        tspan.setAttribute('x', x);
        if (i !== 0) tspan.setAttribute('dy', `${lineHeight}em`);

        tspan.textContent = line;
        info.appendChild(tspan);
    });

    svg.appendChild(info);
}


/**
 * Appends an edge to the given SVG root.
 * Equivalent HTML example: <line x1="300" y1="70" x2="150" y2="270" />
 * 
 * @param {SVGElement} svg - The SVG root element to append to.
 * @param {int} x1 - The X coordinate of the first node.
 * @param {int} y1 - The Y coordinate of the first node. 
 * @param {int} x2 - The X coordinate of the second node. 
 * @param {int} y2 - The Y coordinate of the second node. 
 */
function displayEdge(svg, x1, y1, x2, y2) {
    if (!svg || typeof svg.appendChild !== 'function')
        alert('svg must be a valid SVG element');

    const line = document.createElementNS(SVG_NS, 'line');

    line.setAttribute('x1', x1);
    line.setAttribute('y1', y1);
    line.setAttribute('x2', x2);
    line.setAttribute('y2', y2);

    svg.appendChild(line);
}

/**
 * Appends a node to the given SVG root.
 * Equivalent HTML example:
 * <g class="ast-node" transform="translate(450,270)" tabindex="0">
 *      <circle class="ast-circle" r="64"></circle>
 *      <text class="name" x="0" y="-10" text-anchor="middle" dominant-baseline="middle">spec</text>
 *
 *     <g class="label-box" transform="translate(0,22)" aria-hidden="false">
 *          <rect x="-56" y="-12" width="110" height="24"></rect>
 *          <text x="-50" y="2" font-weight="600" text-anchor="middle"
 *              dominant-baseline="middle">"requires x > 0..."</text>
 *      </g>
 *  </g>
 * 
 * @param {SVGElement} svg - The SVG root element to append to
 * @param {boolean} is_simple - The node is simple or has an additional text
 * @param {int} posX - The position of the node in the X axis
 * @param {int} posY - The position of the node in the Y axis
 * @param {string} name - The text for the main name label (e.g. spec, include, open, etc)
 * @param {string} label - The text for the small label inside the label-box (e.g. 'requires x > 0...')
 * @param {string} color - The color of the inner part of the circle
 */
function displayNode(svg, posX, posY, name, label, color) {
    if (!svg || typeof svg.appendChild !== 'function')
        alert('svg must be a valid SVG element');

    const is_simple = label == "";

    // outer group
    const g = document.createElementNS(SVG_NS, 'g');
    g.setAttribute('class', 'ast-node');
    g.setAttribute('transform', `translate(${posX},${posY})`);
    g.setAttribute('tabindex', '0');

    // circle
    const circle = document.createElementNS(SVG_NS, 'circle');
    circle.style.fill = color;
    circle.setAttribute('class', 'ast-circle');
    circle.setAttribute('r', node_radius.toString());

    // main name text
    const nameText = document.createElementNS(SVG_NS, 'text');
    nameText.setAttribute('class', 'name');
    nameText.setAttribute('x', '0');
    nameText.setAttribute('y', is_simple ? '0' : '-10');
    nameText.setAttribute('text-anchor', 'middle');
    nameText.setAttribute('dominant-baseline', 'middle');
    nameText.textContent = name;

    g.appendChild(circle);
    g.appendChild(nameText);

    if (is_simple) {
        svg.appendChild(g);
        return;
    }

    // label box group
    const labelGroup = document.createElementNS(SVG_NS, 'g');
    labelGroup.setAttribute('class', 'label-box');
    labelGroup.setAttribute('transform', 'translate(0,22)');
    labelGroup.setAttribute('aria-hidden', 'false');

    const rect = document.createElementNS(SVG_NS, 'rect');
    rect.setAttribute('x', '-56');
    rect.setAttribute('y', '-12');
    rect.setAttribute('width', '110');
    rect.setAttribute('height', '24');

    const labelText = document.createElementNS(SVG_NS, 'text');
    // TODO: alinhar e cortar label (fazer depender do comprimento da string)
    labelText.setAttribute('x', '-50');
    labelText.setAttribute('y', '2');
    labelText.setAttribute('font-weight', '600');
    labelText.setAttribute('text-anchor', 'middle');
    labelText.setAttribute('dominant-baseline', 'middle');
    labelText.textContent = label;

    // assemble
    labelGroup.appendChild(rect);
    labelGroup.appendChild(labelText);
    g.appendChild(labelGroup);
    svg.appendChild(g);
}
