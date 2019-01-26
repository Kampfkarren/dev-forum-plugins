import showModal from "discourse/lib/show-modal"
import { withPluginApi } from "discourse/lib/plugin-api"

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
			let definition = names.find((definition) => definition.word === name && definition.locale === I18n.locale)
			let modal = showModal("definition-modal")
			modal.set("name", name)
			modal.set("definition", definition.definition)
		})

		withPluginApi("0.8.24", api => {
			api.decorateCooked($elem => {
				if(api.getCurrentUser().get("custom_fields").disable_definitions) {
					return
				}

				for(let definition of names) {
					let name = definition.word
					if(definition.locale === I18n.locale) {
						$elem.find(`*:contains('${$.escapeSelector(name)}')`).html((_, html) => {
							// HACK: For whatever reason, the old HTML persists
							html = html.replace(REMOVE_OLD_HTML, "$1")
							html = html.replace(new RegExp(`\\b(${regexEscape(name)})\\b`, "gi"), `<span class="discourse-definitions-definition" data-name="${name}">$1</span>`)
							return html
						})
					}
				}
			})

			api.modifyClass("controller:preferences/interface", {
				actions: {
					save() {
						this.get("saveAttrNames").push("custom_fields")
						this._super()
					}
				}
			})
		})
	}
}
