import {GraphGenerator} from "./graph_generator.js";
import {Movement} from "./movement.js";

/**
 * Generates references to other nodes when a node is selected
 */
export class FocusListener {

    #graphGenerator;

    #inPath
    #outPath

    #selectedElementHeight = null;
    //const
    refEnvironmentClass = "refEnvironment"

    constructor(graphGenerator) {
        this.#graphGenerator = graphGenerator;
    }

    /**
     * Generates references for given node
     * @param element Node to generate the references for
     * @param key Label of the node
     */
    selectEvent(element, key) {
        // hide all other lines
        this.#selectedElementHeight = element.clientHeight
        this.#graphGenerator.selectDisconnectedPaths(key).classed("hidden", true)

        this.#inPath = this.#getInPath(key)
        this.#outPath = this.#getOutPath(key)

        this.#expandInReferences(this.#inPath, element)
        this.#expandOutReferences(this.#outPath, element)
    }

    /**
     * Removes generated references
     * @param _ Not used
     */
    deselectEvent(_) {
        if (this.#inPath !== undefined) {
            this.#resetPathSelection(this.#inPath, true)
        }
        if (this.#outPath !== undefined) {
            this.#resetPathSelection(this.#outPath, false)
        }
        d3.selectAll("." + this.refEnvironmentClass).remove()
        this.#graphGenerator.lines.selectAll('path').classed("hidden", false)
    }

    //private

    #getPath(attr, key) {
        return this.#graphGenerator.lines.selectAll('path').filter(function () {
            return d3.select(this).attr(attr) === key;
        })
    }

    #getOutPath(key) {
        return this.#getPath(GraphGenerator.PATH_SRC, key)
    }

    #getInPath(key) {
        return this.#getPath(GraphGenerator.PATH_DEST, key)
    }

    #getSpaces(count) {
        return this.#graphGenerator.getExpandedWidth() / count
    }

    #getDisplacement(i, space, count) {
        return space * (i - (count - 1) / 2)
    }

    #generateD3RefEnvironment(d3Selection, prepend) {
        let selection = d3Selection.select('div.innerNode')
        if (prepend) {
            selection = selection.insert("div", ":first-child")
        } else {
            selection = selection.append("div")
        }
        selection = selection.classed(this.refEnvironmentClass, true)
            .style("position", "relative")
            .append('div')
            .style("position", "absolute")
            .style("left", "50%")
        if (prepend) {
            selection = selection.style("bottom", "0")
        }
        return selection;
    }

    #generateD3ReferencesAbsoluteWrapper(d3Selection, displacementFunction) {
        return d3Selection.append('div')
            .style("position", "relative")
            .classed("referenceDescriptionWrapper", true)
            .style("left", (d, i) => displacementFunction(d, i) + "px")
    }

    #generateD3References(d3Selection, isReferencingSource, absolutePositioning) {
        let getRefTarget = obj => isReferencingSource ? obj.source : obj.destination
        return d3Selection
            .append('ref')
            .on("click", Movement.refClickWrapper)
            .attr("title", d => this.#graphGenerator.nodeData[getRefTarget(d3.select(d).datum())].type)
            .attr("class", d => this.#graphGenerator.nodeData[getRefTarget(d3.select(d).datum())].type)
            .classed("referenceDescription", true)
            .classed("referenceTop", !isReferencingSource)
            .classed("referenceAbsolute", absolutePositioning)
            .classed("referenceBottom", isReferencingSource)
            .text(d => this.#graphGenerator.nodeData[getRefTarget(d3.select(d).datum())].title)
            .attr("target", d => getRefTarget(d3.select(d).datum()).toString())
    }

    #generateText(element, paths, space, top) {
        const width = 110
        const absolutePos = space > width

        let selection = d3.select(element)
        selection = this.#generateD3RefEnvironment(selection, !top);
        let toRerender = selection.node()
        let scrollContainer = null
        if (!absolutePos) {
            selection = selection.append("div")
                .classed("refEnvironmentScroller", true)
            scrollContainer = selection.node()
            scrollContainer.addEventListener("wheel", (evt) => {
                evt.preventDefault();
                scrollContainer.scrollLeft += evt.deltaY;
            });
            selection = selection.append("div")
                .classed("refScrollerItems", true)
        }
        selection = selection
            .selectAll('ref')
            .data(paths)
            .enter()
        let displacement = (d, i) => this.#getDisplacement(i, space, paths.size())
        if (!absolutePos) {
            displacement = (d, i) => null
        }
        selection = this.#generateD3ReferencesAbsoluteWrapper(selection, displacement)
        this.#generateD3References(selection, top, absolutePos)

        if (scrollContainer != null) {
            scrollContainer.scrollTo({left: 100000000000, behavior: 'smooth'});
        }

        MathJax.Hub.Queue(['Typeset', MathJax.Hub, toRerender]);
    }

    #expandInReferences(paths, element) {
        const self = this
        const space = this.#getSpaces(paths.size())
        paths = paths.sort(function (a, b) {
            return self.#graphGenerator.nodeData[a.source].x - self.#graphGenerator.nodeData[b.source].x
        })
        paths.each(function (d, i) {
            let curve = self.#graphGenerator.generateOutboundCurve({
                    x: self.#graphGenerator.nodeData[d.destination].x + self.#getDisplacement(i, space, paths.size()),
                    y: self.#graphGenerator.nodeData[d.destination].y + (self.#graphGenerator.getExpandedHeight()) - 135
                },
                {
                    x: self.#graphGenerator.nodeData[d.source].x,
                    y: self.#graphGenerator.nodeData[d.source].y
                }
            )
            d3.select(this).attr('d', curve)
        })
        this.#generateText(element, paths, space, true);
        return paths
    }

    #expandOutReferences(paths, element) {
        const self = this
        const space = this.#getSpaces(paths.size())
        paths = paths.sort(function (a, b) {
            return self.#graphGenerator.nodeData[a.destination].x - self.#graphGenerator.nodeData[b.destination].x
        })
        paths.each(function (d, i) {
            let curve = self.#graphGenerator.generateOutboundCurve({
                    x: self.#graphGenerator.nodeData[d.destination].x,
                    y: self.#graphGenerator.nodeData[d.destination].y
                },
                {
                    x: self.#graphGenerator.nodeData[d.source].x + self.#getDisplacement(i, space, paths.size()),
                    y: self.#graphGenerator.nodeData[d.source].y
                }
            )
            d3.select(this).attr('d', curve)
        })

        this.#generateText(element, paths, space, false)
        return paths
    }

    #resetPathSelection(path, inPaths) {
        const self = this
        path.each(function (d) {
            d3.select(this).attr('d', self.#graphGenerator.generateDefaultCurveFromKey(
                    d.destination,
                    d.source,
                    inPaths ? self.#selectedElementHeight : undefined
                )
            )
        })
    }
}