import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const SECONDS_IN_A_DAY = 60 * 60 * 24;

export default Ember.Controller.extend({
	actions: {
		submit() {
			let start = this.get("start_date")
			let end = this.get("end_date")
			let category = this.get("category")

			if(!start || !end || !category) return;

			ajax("/admin/plugins/discourse-solved-rates", {
				data: {
					start_date: new Date(start).getTime() / 1000,
					end_date: (new Date(end).getTime() / 1000) + SECONDS_IN_A_DAY,
					category: category
				},

				method: "POST"
			}).then((data) => {
				this.set("hasRate", true)
				this.set("rate", data.rate * 100)
			}).catch(popupAjaxError)
		}
	}
})
