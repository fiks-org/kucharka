/**
 * Highlights references when node is being hovered over
 */
export class ReferenceBoldnessListener {

    #graphGenerator
    #selectionActive = false

    constructor(graphGenerator) {
        this.#graphGenerator = graphGenerator
    }

    /**
     * Call when element is selected to indicate it should not react to hover events
     * @param _ Not used
     * @param key label of selected element
     */
    selectEvent(_, key) {
        this.#selectionActive = true
        this.hoverEnd(undefined, key)
    }

    /**
     * Call when element is deselected to indicate it should react to hover events
     * @param _ Not used
     */
    deselectEvent(_) {
        this.#selectionActive = false
    }

    /**
     * Call when hover event starts to highlight related references and suppress unrelated
     * @param _ Not used
     * @param key Label of node being hovered over
     */
    hoverStart(_, key) {
        if (!this.#selectionActive) {
            this.#graphGenerator.selectConnectedPaths(key).classed("hovered", true)
            this.#graphGenerator.selectDisconnectedPaths(key).classed("notHovered", true)
        }
    }

    /**
     * Call when hover event ends to reset highlighting and supressing
     * @param _ Not used
     * @param key Label of node that was being hovered over
     */
    hoverEnd(_, key) {
        this.#graphGenerator.selectConnectedPaths(key).classed("hovered", false)
        this.#graphGenerator.selectDisconnectedPaths(key).classed("notHovered", false)
    }
}