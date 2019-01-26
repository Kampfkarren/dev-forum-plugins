import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from 'discourse/lib/plugin-api';
//import showModal from "discourse/lib/show-modal";

export default {
	name: 'new-member-lock',
	initialize() {
		withPluginApi('0.8.24', function(api) {
			const user = api.getCurrentUser()

			if(!user) return

			if(user.trust_level >= api.container.lookup('site-settings:main').new_member_lock_minimum_tl) {
				// User is allowed to see the button
				let topic = api.container.lookup("controller:topic")

				api.decorateWidget('topic-admin-menu:adminMenuButtons', (decorator) => {
					// Adds the button to the admin menu
					return {
						icon: 'ban',
						fullLabel: topic.model.closed_to_new_members ? 'new_member_lock.button_label_unlock' : 'new_member_lock.button_label_lock',
						action: 'actionLockNewMember'
					}
				})
				
				api.attachWidgetAction('topic-admin-menu', 'actionLockNewMember', function() {
					// The button was clicked
					let topicId = topic.model.id
					let closed = topic.model.closed_to_new_members
					topic.model.set('closed_to_new_members', !closed)

					ajax({
						url: `/t/${topicId}/new-member-lock`,
						type: 'POST'
					})
				})
			}
		})
	}
}