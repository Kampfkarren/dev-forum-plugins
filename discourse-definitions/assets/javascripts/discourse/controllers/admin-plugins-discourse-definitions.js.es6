import {
	default as computed,
} from "ember-addons/ember-computed-decorators"
import { ajax } from "discourse/lib/ajax"
import { popupAjaxError } from "discourse/lib/ajax-error"

export default Ember.Controller.extend({
	definitions: Discourse.Site.currentProp("discourse_definitions"),

	actions: {
		delete(params) {
			ajax("/admin/plugins/discourse-definitions", {
				data: params,
				method: "DELETE"
			}).then((definitions) => {
				this.set("definitions", definitions.discourse_definitions)
			}).catch(popupAjaxError)
		},

		edit(params) {
			let definition = this.definitions.find((definition) => params.word === definition.word && params.locale === definition.locale)
			this.set("new_definition", definition.definition)
			this.set("new_locale", definition.locale)
			this.set("new_word", definition.word)
		},

		new() {
			ajax("/admin/plugins/discourse-definitions", {
				data: {
					definition: this.get("new_definition"),
					locale: this.get("new_locale"),
					word: this.get("new_word"),
				},

				method: "POST"
			}).then((definitions) => {
				this.set("definitions", definitions.discourse_definitions)
			}).catch(popupAjaxError)
		},
	},

	@computed()
	availableLocales() {
		return JSON.parse(this.siteSettings.available_locales)
	},
})
