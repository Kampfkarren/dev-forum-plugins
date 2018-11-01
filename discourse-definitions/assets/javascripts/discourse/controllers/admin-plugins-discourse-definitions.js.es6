import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Controller.extend({
	definitions: Discourse.Site.currentProp("discourse_definitions"),

	actions: {
		delete(name) {
			ajax("/admin/plugins/discourse-definitions", {
				data: {
					word: name,
				},

				method: "DELETE"
			}).then((definitions) => {
				this.set("definitions", definitions)
			}).catch(popupAjaxError)
		},

		new() {
			ajax("/admin/plugins/discourse-definitions", {
				data: {
					definition: this.get("new_definition"),
					word: this.get("new_word"),
				},

				method: "POST"
			}).then((definitions) => {
				this.set("definitions", definitions)
			}).catch(popupAjaxError)
		},
	}
})
