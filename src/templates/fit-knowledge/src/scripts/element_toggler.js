/**
 * Shows and hides an element on click of another element
 */
export class ElementToggler {

    #visible;
    #toggledElement;

    /**
     * @param activatorElement Element to register on click behaviour
     * @param toggledElement Element to show and hide on click of activatorElement
     */
    constructor(activatorElement, toggledElement) {
        this.#toggledElement = toggledElement
        this.#visible = false;
        activatorElement.on("click", this.#clicked.bind(this))

    }

    #appear() {
        this.#toggledElement.style("display", "block")
    }

    #disappear() {
        this.#toggledElement.style("display", "none")
    }

    #clicked() {
        window.clearTimeout(this.timeout)
        if (this.#visible) {
            this.#disappear()
        } else {
            this.#appear()
        }
        this.#visible = !this.#visible;
    }
}