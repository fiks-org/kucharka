import {Utility} from "./utility.js";

export class Movement {
    //d3
    static zoom;

    //sizes of node when zoomed in
    static #SCALE = 1
    static #DEFAULT_SCALE = 0.3

    //animation
    static #ANIMATION_DURATION = 1250

    //class
    static #selectedElement = undefined;
    static #zooming = false;

    static #generator;

    static #transform
    static #transformBeforeSelect = null;

    static #selectionListeners = []

    /**
     * @returns {number} Default scale to display elements at
     */
    static getDefaultScale() {
        return Movement.#DEFAULT_SCALE
    }

    /**
     * @returns {number} How far node is from the top of the screen when selected
     */
    static getMarginTop() {
        if (window.innerWidth >= 2000) {
            return 220;
        }
        if (window.innerWidth <= 1000 && window.innerWidth > 600) {
            return 130
        }
        if (window.innerWidth <= 600) {
            return 110
        }
        return 110
    }

    /**
     * Initiates the Movement class
     * @param generator Instance of GraphGenerator class
     */
    static activate(generator) {
        Movement.#generator = generator
        Movement.#transform = Movement.getDefaultTransform();


        Movement.zoom = d3.zoom()
            .scaleExtent([.05, 1])
            //.translateExtent([[-50, -50], [1000, 1000]]) todo: make this based on data
            .on("zoom", Movement.#zoomed)
            .on("end", Movement.#zoomEnd)
            .on("start", Movement.#zoomStart)
        Movement.#generator.container
            .call(Movement.zoom)
            .call(Movement.zoom.transform, d3.zoomIdentity.translate(Movement.#transform.x, Movement.#transform.y).scale(Movement.#transform.k))

        d3.selectAll('ref').on("click", Movement.refClickWrapper)
        generator.app.style('transform-origin', '0 0')
        generator.nodeHeading.on("click", Movement.#clicked)
        generator.container.call(Movement.zoom)
    }

    /**
     * @returns {{x, y, chapter, content, label, referenced_by, required_in_proof_of, type, title, weight}} Object of the top element in the mind map
     */
    static getDefaultFocusedElement() {
        return Object.values(Movement.#generator.nodeData).reduce(function (prev, curr) {
            return prev.y < curr.y ? prev : curr;
        })
    }

    /**
     * @returns {k, x, y} Position the view should be in when the application loads
     */
    static getDefaultTransform() {
        let top = Movement.getDefaultFocusedElement()
        return Movement.calculateZoomDestination(top, Movement.#DEFAULT_SCALE)
    }

    /**
     * Zooms to given position
     * @param dest {k, x, y}, Position to zoom to
     */
    static zoomTo(dest) {
        Movement.#generator.container.transition().duration(Movement.#ANIMATION_DURATION)
            .call(Movement.zoom.transform,
                dest
            )
    }

    /**
     * Registers class to call whenever a node is selected
     * @param listener Class that implements selectEvent and deselectEvent, for example class UrlManager
     */
    static registerListener(listener) {
        Movement.#selectionListeners.push(listener)
    }

    /**
     *
     * @param obj {x, y, chapter, content, label, referenced_by, required_in_proof_of, type, title, weight} Node to zoom to
     * @param scale How far should it be zoomed
     * @returns {k, x, y} Position to zoom to to see obj
     */
    static calculateZoomDestination(obj, scale) {
        return d3.zoomIdentity.scale(scale).translate(-obj.x + window.innerWidth / (scale * 2), -obj.y + Movement.getMarginTop() / scale);
    }

    /**
     * Zoom from one zoomed in node to another using ref element
     * @param targetId label of target node
     */
    static refClick(targetId) {
        Movement.#transformBeforeSelect = null
        Movement.deselectNode(true);
        let targetElementSelection = d3.select("#" + Utility.labelToId(targetId))
        Movement.selectNode(targetId, targetElementSelection.node())
        let targetData = Movement.#generator.nodeData[targetElementSelection.datum()]
        Movement.#transformBeforeSelect = Movement.calculateZoomDestination(targetData, Movement.#DEFAULT_SCALE)
    }

    /**
     * Call when node is being deselected
     * @param refclicked true if deselecting because of moving and zooming in to another node, false if deselecting because of zooming out
     */
    static deselectNode(refclicked) {
        let prevSelected = Movement.#selectedElement;
        Movement.#selectedElement?.classList.remove('selected')
        Movement.#selectedElement = undefined;
        if (Movement.#transformBeforeSelect !== null || refclicked) {
            Movement.#selectionListeners.forEach(x => x.deselectEvent(prevSelected, refclicked))
        }
        if (Movement.#transformBeforeSelect !== null) {
            Movement.zoomTo(d3.zoomIdentity.translate(Movement.#transformBeforeSelect.x, Movement.#transformBeforeSelect.y).scale(Movement.#transformBeforeSelect.k));
            Movement.#transformBeforeSelect = null;
        }
    }

    /**
     * Call when node is selected
     * @param key label of the node
     * @param element HTML element of the node
     */
    static selectNode(key, element) {
        if (Movement.#transformBeforeSelect !== null) {
            return
        }
        if (element === undefined) {
            element = Utility.getElementByKey(key)
        }
        Movement.deselectNode()
        Movement.#selectedElement = element
        Movement.#selectionListeners.forEach(x => x.selectEvent(element, key))
        Movement.#transformBeforeSelect = Movement.#transform;
        Movement.#zooming = true;
        element.classList.add('selected')
        Movement.zoomTo(Movement.calculateZoomDestination(Movement.#generator.nodeData[key], Movement.#SCALE));
    }

    /**
     * Wrapper for event handler on click
     * @param event
     */
    static refClickWrapper(event) {
        let targetId = event.target.getAttribute("target");
        Movement.refClick(targetId)
    }

    //PRIVATE

    static #zoomed(event) {
        Movement.#transform = event.transform;
        Movement.#generator.app.style("transform", "translate(" + Movement.#transform.x + "px," + Movement.#transform.y + "px) scale(" + Movement.#transform.k + ")");
        Movement.#generator.app.style('transform-origin', '0 0')

    }

    static #zoomStart(event) {
        if (!Movement.#zooming) {
            Movement.deselectNode()
        }
    }

    static #zoomEnd(event) {
        Movement.#zooming = false
    }

    static #clicked(pointerEvent, d) {
        Movement.selectNode(d, pointerEvent.target.parentElement.parentElement);
    }
}