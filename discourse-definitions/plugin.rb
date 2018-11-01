# name: discourse-definitions
# version: 1.0.0
# authors: boyned/Kampfkarren

add_admin_route "discourse_definitions.title", "discourse-definitions"

register_asset "stylesheets/common/discourse-definitions.scss"

after_initialize do
	add_to_serializer(:site, :discourse_definitions) do
		PluginStore.get("discourse_definitions", "definitions") || {}
	end

	module ::DiscourseDefinitions
		class Engine < ::Rails::Engine
			engine_name "discourse_definitions"
			isolate_namespace DiscourseDefinitions
		end
	end

	class DiscourseDefinitions::DiscourseDefinitionsController < ::ApplicationController
		def delete
			name = params[:word]
			raise Discourse::InvalidParameters.new(:name) if name.blank?
			definitions = ::PluginStore.get("discourse_definitions", "definitions") || {}
			raise Discourse::NotFound if definitions[name].nil?
			definitions.delete name
			::PluginStore.set("discourse_definitions", "definitions", definitions)
			render json: definitions
		end

		def new
			name = params[:word]
			definition = params[:definition]
			raise Discourse::InvalidParameters.new(:name) if name.blank?
			raise Discourse::InvalidParameters.new(:definition) if definition.blank?
			definitions = ::PluginStore.get("discourse_definitions", "definitions") || {}
			definitions[name] = definition
			::PluginStore.set("discourse_definitions", "definitions", definitions)
			render json: definitions
		end
	end

	require_dependency "staff_constraint"

	DiscourseDefinitions::Engine.routes.draw do
		post "/admin/plugins/discourse-definitions" => "discourse_definitions#new", constraints: StaffConstraint.new
		delete "/admin/plugins/discourse-definitions" => "discourse_definitions#delete", constraints: StaffConstraint.new
	end

	Discourse::Application.routes.append do
		get "/admin/plugins/discourse-definitions" => "admin/plugins#index", constraints: StaffConstraint.new
		mount ::DiscourseDefinitions::Engine, at: "/"
	end
end
