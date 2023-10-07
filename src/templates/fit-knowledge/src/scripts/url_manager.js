import {Movement} from "./movement.js";

/**
 * Handles url, changes the url when nodes are selected
 */
export class UrlManager {
    #selectedKey = null
    #urlChangeInProcess = false
    #generator
    #prevState = null

    STATE_IN = "i"
    STATE_OUT = "o"

    constructor(generator) {
        this.#generator = generator
        window.addEventListener('popstate', (popstate) => {
            if (popstate.state === null) {
                this.handleInitialUrl()
            } else {
                this.handleUrlChange(popstate.state["key"], popstate.state["selected"])
            }
        })
    }

    /**
     * Call when url has changed, uses Movement class to move to the correct position
     * @param key
     * @param selected
     */
    handleUrlChange(key, selected) {
        this.#urlChangeInProcess = true
        try {
            if (selected) {
                Movement.refClick(key)
            } else {
                let targetData = this.#generator.nodeData[key]
                Movement.zoomTo(Movement.calculateZoomDestination(targetData, Movement.getDefaultScale()))
            }
        } finally {
            this.#urlChangeInProcess = false
        }
    }

    /**
     * Checks current url. If specified in url, calls Movement class to move to the element. Should be called after Movement.activate()
     */
    handleInitialUrl() {
        this.#urlChangeInProcess = true
        try {
            let url = window.location.href.split('#')
            if (url.length === 1) {
                this.handleUrlChange(Movement.getDefaultFocusedElement().label, false)
            } else {
                let loc = url[url.length - 1]
                let vals = loc.split("/")
                if (vals.length !== 2 || (vals[0] !== this.STATE_IN && vals[0] !== this.STATE_OUT) || !this.#generator.nodeKeys.includes(vals[1])) {
                    throw new Error("404: url '" + loc + "' not found")
                }
                let selected = vals[0] === this.STATE_IN
                let key = vals[1]
                this.handleUrlChange(key, selected)
            }
        } finally {
            this.#urlChangeInProcess = false
        }
    }

    /**
     * Call when node is selected, changes the url accordingly
     * @param _ Not used
     * @param key label of selected node
     */
    selectEvent(_, key) {
        this.#selectedKey = key
        if (!this.#urlChangeInProcess) {
            this.#handleStatePush(key, true)
        }
    }

    /**
     * Call when node is deselected, changes the url to deselected state
     * @param _ Not used
     * @param refClicked true if moving from selected node to another selected node, otherwise false
     */
    deselectEvent(_, refClicked) {
        if (!this.#urlChangeInProcess && !refClicked) {
            this.#handleStatePush(this.#selectedKey, false);
        }
    }

    /**
     * Changes the url
     * @param key label of node the url should point to
     * @param zoomedIn true if zoomed to a node, false if not zoomed
     */
    #handleStatePush(key, zoomedIn) {
        let nextState = {"key": key, "selected": zoomedIn}
        if (!UrlManager.#statesEqual(this.#prevState, nextState)) {
            window.history.pushState(nextState, "", "#" + (zoomedIn ? this.STATE_IN : this.STATE_OUT) + "/" + key)
        }
        this.#prevState = nextState
    }

    static #statesEqual(stateA, stateB) {
        if (stateA === stateB) {
            return true
        }
        if (stateA === null || stateB === null) {
            return false
        }
        return stateA["key"] === stateB["key"] && stateA["selected"] === stateB["selected"]
    }
}