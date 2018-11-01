import { cookAsync } from "discourse/lib/text";
import { withPluginApi } from "discourse/lib/plugin-api";

const MARGIN_BOTTOM = 15
const REMOVE_OLD_HTML = /<span class="discourse-definitions-definition" data-name="[^"]+">([^<]+)<\/span>/g

const regexEscape = (s) => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

export default {
	name: "discourse-definitions",

	initialize() {
		let names = Discourse.Site.currentProp("discourse_definitions")

		let tooltip = $("<div class='discourse-definitions-tooltip'></div>")
		$("body").append(tooltip)
		tooltip.hide()

		$(document).click(() => {
			tooltip.hide()
		})

		$(document).on("click", ".discourse-definitions-definition", function(event){
			event.stopPropagation()
			let name = $(this).attr("data-name")
			let offset = $(this).offset()
			let definition = names[name]
			cookAsync(definition).then(cookedDefinition => {
				tooltip.html(`<b>${name}</b><br>`)
				tooltip.append(cookedDefinition.string)
				tooltip.show()
				tooltip.css("top", `${offset.top + MARGIN_BOTTOM}px`)
				tooltip.css("left", `${offset.left}px`)
			})
		})

		withPluginApi("0.8.24", api => {
			api.decorateCooked($elem => {
				for(let name in names) {
					$elem.find(`*:contains('${$.escapeSelector(name)}')`).html((_, html) => {
						// HACK: For whatever reason, the old HTML persists
						html = html.replace(REMOVE_OLD_HTML, "$1")
						html = html.replace(new RegExp(`\\b(${regexEscape(name)})\\b`, "gi"), `<span class="discourse-definitions-definition" data-name="${name}">$1</span>`)
						return html
					})
				}
			})
		})
	}
}
