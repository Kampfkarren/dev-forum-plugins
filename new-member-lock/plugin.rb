# name: new-member-lock
# version: 1.0.0
# authors: boyned/Kampfkarren

enabled_site_setting :new_member_lock_minimum_tl

after_initialize do
	Topic.register_custom_field_type("closed_to_new_members", :boolean)
	
	add_to_serializer(:topic_view, :closed_to_new_members, false) do
		object.topic.custom_fields["closed_to_new_members"]
	end

	# Prevent name conflicts
	module ::DevForumNewMemberLock
		class Engine < ::Rails::Engine
			engine_name "discourse_tl_post_lock"
			isolate_namespace DevForumNewMemberLock
		end

		module NewMemberTopicGuardian
			def can_create_post_on_topic?(topic)
				super(topic) && (!topic.custom_fields["closed_to_new_members"] || current_user.has_trust_level?(TrustLevel[2]))
			end
		end

		include ::TopicGuardian
		::TopicGuardian.module_eval { include NewMemberTopicGuardian }

		class ::Guardian
			include NewMemberTopicGuardian
		end
	end

	class DevForumNewMemberLock::NewMemberLockController < ::ApplicationController
		before_action :ensure_logged_in
		before_action :ensure_enough_perms

		def ensure_enough_perms
			raise Discourse::InvalidAccess.new("You don't have a high enough trust level.") if current_user.trust_level < SiteSetting.new_member_lock_minimum_tl
		end

		def change
			# At this point, we've already validated access
			level = params[:level]
			#raise Discourse::InvalidParameters.new unless (1..4)
			topic = Topic.find_by_id(params[:id])
			raise Discourse::NotFound if topic.nil? || topic.trashed?

			closed = !topic.custom_fields["closed_to_new_members"]
			topic.custom_fields["closed_to_new_members"] = closed

			topic.add_small_action(current_user, "closed_to_new_member_#{closed}")

			topic.save_custom_fields
		end
	end

	DevForumNewMemberLock::Engine.routes.draw do
		post "/t/:id/new-member-lock" => "new_member_lock#change"
	end

	Discourse::Application.routes.append do
		mount ::DevForumNewMemberLock::Engine, at: "/"
	end
end
