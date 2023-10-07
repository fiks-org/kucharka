import {Utility} from "./scripts/utility.js";
import {GraphGenerator} from "./scripts/graph_generator.js";
import {FocusListener} from "./scripts/focus_listener.js"
import {Movement} from "./scripts/movement.js";
import {UrlManager} from "./scripts/url_manager.js";
import {ReferenceBoldnessListener} from "./scripts/reference_boldness_listener.js";
import {ElementToggler} from "./scripts/element_toggler.js";

/**
 * Called on launch, loads everything and then removes loading screen
 */
function startMindMap() {
    Utility.loadData(async function (response) {
        let jsonData = JSON.parse(response);

        d3.select("#legend").append("div").classed("timestamp", true).text(jsonData["timestamp"])
        new ElementToggler(d3.select("#info"), d3.select("#legendWrapper"))

        let title = jsonData.meta?.document?.title
        if (title !== undefined) {
            document.title = title
        }

        let app = d3.select('#app')
        let lines = d3.select('#lines')
        let container = d3.select('#container')

        let gg = new GraphGenerator(app, lines, container, jsonData)
        await gg.generate()

        let boldOnHover = new ReferenceBoldnessListener(gg)
        gg.registerHoverListener(boldOnHover)
        Movement.activate(gg)

        Movement.registerListener(boldOnHover)
        let focusListener = new FocusListener(gg)
        Movement.registerListener(focusListener)

        let urlManager = new UrlManager(gg)
        Movement.registerListener(urlManager)

        Utility.disappear(d3.select("#loading"))
        urlManager.handleInitialUrl()
    }, "graph.json");
}

Utility.allLoaded().then(promise => startMindMap())