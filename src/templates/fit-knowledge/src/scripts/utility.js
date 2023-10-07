/**
 * Utility class
 */
export class Utility {
    /**
     * Loads data from file
     * @param callback function to call when the file is loaded
     * @param path path to the file
     */
    static loadData(callback, path) {
        var xobj = new XMLHttpRequest();
        xobj.overrideMimeType("application/json");
        xobj.open('GET', path, false);
        xobj.onreadystatechange = function () {
            if (xobj.readyState == 4 && xobj.status == "200") {
                callback(xobj.responseText);
            }
        };
        xobj.send(null);
    }

    /**
     * Converts element label to id of HTML element
     * @param label label to convert to id
     * @returns {string} id of HTML element
     */
    static labelToId(label) {
        return "node_" + label;
    }

    //source: https://codepen.io/eanbowman/pen/jxqKjJ
    /**
     * Returns promise resolve once MathJax is loaded or reject if it doesn't load in 30 seconds
     * @returns {Promise<unknown>}
     */
    static allLoaded() {
        const start = Date.now();
        const timeout = 30 * 1000 //30 seconds
        return new Promise(waitForMathJax);

        function waitForMathJax(resolve, reject) {
            //https://stackoverflow.com/questions/5113374/javascript-check-if-variable-exists-is-defined-initialized
            if (typeof MathJax !== "undefined") {
                resolve(MathJax);
            } else if (timeout && (Date.now() - start) >= timeout) {
                reject(new Error("timeout"));
            } else {
                setTimeout(waitForMathJax.bind(this, resolve, reject), 30);
            }
        }
    }

    /**
     * Returns element by its label
     * @param key Label of the element
     * @returns {*} D3 selection of the element
     */
    static getElementByKey(key) {
        return d3.select("#" + Utility.labelToId(key)).node()
    }

    /**
     * Nicely delete an element(s) by fading it out
     * @param element D3 selection of the element(s)
     */
    static disappear(element) {
        const speed = 1000
        element.style("transition", "opacity " + speed + "ms ease");
        element.style("opacity", 0);
        setTimeout(() => element.remove(), speed);
    }
}