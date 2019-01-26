# name: new-member-redirect
# version: 1.0.0
# authors: boyned/Kampfkarren

after_initialize do
	DiscourseEvent.on(:topic_created) do |post|
		new_member_prohibited_category = SiteSetting.new_member_prohibited_category
		new_member_redirect_to = SiteSetting.new_member_redirect_to
		lead_top_contributors = SiteSetting.lead_top_contributors

		next unless new_member_prohibited_category.present? &&
						new_member_redirect_to.present? &&
						lead_top_contributors.present?
		if post.user&.trust_level == TrustLevel[1]
			# New member
			if post.category&.parent_category&.id.to_i == new_member_prohibited_category.to_i
				post.change_category_to_id(new_member_redirect_to)
				post.save
				post.reload

				PostCreator.create(post.user,
					title: "Request: Posting Bug Report or Feature Request",
					raw: post.url,
					archetype: Archetype.private_message,
					target_group_names: [lead_top_contributors],
					skip_validations: true)
			end
		end
	end
end
