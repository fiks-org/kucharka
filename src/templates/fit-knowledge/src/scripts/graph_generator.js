import {Utility} from "./utility.js";

/**
 * Generates the mind map
 */
export class GraphGenerator {

    static PATH_SRC = "ref"
    static PATH_DEST = "dest"
    static FONT_SIZE_PX = 48
    static FONT_IMPORTANCE_MULTIPLIER = 0.8

    bezierForce = 600;

    app;
    lines;
    container;

    nodeData;
    nodeKeys;

    nodes;
    nodeHeading;
    nodeBody;

    #hoverHandlers = []

    constructor(app, lines, container, jsonData) {
        this.app = app
        this.lines = lines
        this.container = container

        this.nodeData = jsonData.nodes
        this.nodeKeys = Object.keys(this.nodeData)

        this.textbookUrl = jsonData.meta?.mindmap?.textbook_url

        lines.attr('width', jsonData.canvas.x.toString() + "px")
        lines.attr('height', jsonData.canvas.y.toString() + "px")

    }

    /**
     * @returns {number} Height of node when expanded, should correspond to css
     */
    getExpandedHeight() {
        return (window.innerHeight * 0.9)
    }

    /**
     * @returns {number} Width of node when expanded, should correspond to css
     */
    getExpandedWidth() {
        return (window.innerWidth * 0.9)
    }

    /**
     *
     * @param keyFrom Label of element the curve should start at (top element)
     * @param keyTo Label of element the curve should end et (bottom element)
     * @param originHeight Height of element the curve starts at
     * @returns {string} Svg path of the curve
     */
    generateDefaultCurveFromKey(keyFrom, keyTo, originHeight = undefined) {
        if (originHeight === undefined) {
            originHeight = Utility.getElementByKey(keyFrom).clientHeight
        }
        return this.generateCurve(
            {x: this.nodeData[keyFrom].x, y: this.nodeData[keyFrom].y + originHeight},
            {x: this.nodeData[keyTo].x, y: this.nodeData[keyTo].y}
        )
    }

    generateOutboundCurve(from, to) {
        let output = `M${from.x},${from.y}`;
        output += `c0,${this.bezierForce},${to.x - from.x},0,${to.x - from.x},${to.y - from.y}`;
        return output;
    }

    /**
     *
     * @param from {{x, y}} Coordinates of one of the elements
     * @param to {{x, y}} Coordinates of the other element
     * @returns {string} Svg path of the curve
     */
    generateCurve(from, to) {
        let origin_x = from.x
        let origin_y = from.y
        let destination_x = to.x
        let destination_y = to.y

        return d3.linkVertical()({
            source: [origin_x, origin_y],
            target: [destination_x, destination_y]
        })
    }

    /**
     * Register class to be called whenever node is hovered over
     * @param listener Class that implements
     */
    registerHoverListener(listener) {
        this.#hoverHandlers.push(listener)
    }

    /**
     * @param key Label of the element
     * @returns {*} D3 selection of paths connected to specified element
     */
    selectConnectedPaths(key) {
        return this.lines.selectAll('path').filter(function () {
            return d3.select(this).attr(GraphGenerator.PATH_DEST) === key
                || d3.select(this).attr(GraphGenerator.PATH_SRC) === key;
        })
    }

    /**
     * @param key Label of element
     * @returns {*} D3 selection of all paths that are not connected to specified element
     */
    selectDisconnectedPaths(key) {
        return this.lines.selectAll('path').filter(function () {
            return d3.select(this).attr(GraphGenerator.PATH_DEST) !== key
                && d3.select(this).attr(GraphGenerator.PATH_SRC) !== key;
        })
    }

    /**
     * Generate all nodes, references and parse math using MathJax
     * @returns {Promise<void>}
     */
    async generate() {
        this.nodes = this.app.selectAll('div')
            .data(this.nodeKeys)
            .enter()
            .append('div')
            .attr("class", (key) => this.nodeData[key].type)
            .classed('node', true)
            .attr("id", function (d, i) {
                return Utility.labelToId(d);
            })
            .style('left', key => this.nodeData[key].x + 'px')
            .style('top', key => this.nodeData[key].y + 'px')
            .append('div')
            .classed('innerNode', true)
            .on("mouseover", (d, i) => this.#hoverHandlers.forEach(x => x.hoverStart(d, i)))
            .on("mouseout", (d, i) => this.#hoverHandlers.forEach(x => x.hoverEnd(d, i)))


        this.nodeHeading = this.nodes.append('div')
            .classed('nodeHeading', true)
            .style("font-size", key => (GraphGenerator.FONT_SIZE_PX + GraphGenerator.FONT_IMPORTANCE_MULTIPLIER * this.nodeData[key].weight) + "px")
            .style("font-weight", key => {
                if (this.nodeData[key].weight > 70)
                    return "700"
                return null
            })
            .text(key => this.nodeData[key].title)

        let iconContainer = this.nodes.append('div')
            .classed("textbookRef", true)

        iconContainer.append('span')
            .classed("importance", true)
            .attr("title", "Důležitost")
            .text(key => '!'.repeat(Math.floor(this.nodeData[key].weight / 20)))
        if (this.textbookUrl !== undefined) {
            iconContainer
                .append('a')
                .attr("target", "_blank")
                .attr("href", key => {
                    let url = this.textbookUrl + "/"
                    if (this.nodeData[key].section !== undefined) {
                        url += this.nodeData[key].section
                    } else {
                        url += this.nodeData[key].chapter
                    }
                    url += ".html#" + key
                    return url
                }).append("i")
                .attr("class", "fa-solid fa-arrow-up-right-from-square fa-xl")
        }

        this.nodeBody = this.nodes.append('div')
            .classed('nodeBody', true)
            .html(key => this.nodeData[key].content)
        this.nodes.on("wheel.zoom", GraphGenerator.#stopEvents);
        this.nodes.on("touchstart", GraphGenerator.#stopEvents)
        this.nodes.on("mousedown", GraphGenerator.#stopEvents)


        MathJax.Hub.Queue(['Typeset', MathJax.Hub, d3.select("#app").node()]);
        var processMath = new Promise((resolve, reject) => {
            MathJax.Hub.Queue([() => resolve()])
        })
        await processMath;

        let links = [];
        const self = this
        this.nodes.each(function (key) {
            self.nodeData[key].referenced_by.forEach(ref => {
                if (typeof self.nodeData[ref] !== 'undefined') {
                    links.push({
                            source: ref,
                            destination: key,
                            curve: self.generateDefaultCurveFromKey(key, ref, this.clientHeight),
                            primaryRef: true
                        }
                    )
                }
            })
            self.nodeData[key].required_in_proof_of.forEach(ref => {
                if (typeof self.nodeData[ref] !== 'undefined') {
                    links.push({
                            source: ref,
                            destination: key,
                            curve: self.generateDefaultCurveFromKey(key, ref, this.clientHeight),
                            primaryRef: false
                        }
                    )
                }
            })
        })

        this.lines
            .selectAll('path')
            .data(links)
            .enter()
            .append('path')
            .classed('referencePath', true)
            .classed('secondaryPath', data => !data.primaryRef)
            .attr('d', data => data.curve)
            .attr(GraphGenerator.PATH_SRC, data => data.source)
            .attr(GraphGenerator.PATH_DEST, data => data.destination)
    }

    //PRIVATE

    static #stopEvents(event, data) {
        event.stopPropagation()
    }
}