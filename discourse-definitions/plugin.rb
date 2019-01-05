# name: discourse-definitions
# version: 1.0.0
# authors: boyned/Kampfkarren

add_admin_route "discourse_definitions.title", "discourse-definitions"

register_asset "stylesheets/common/discourse-definitions.scss"

after_initialize do
	require_dependency "locale_site_setting"
	require_dependency "staff_constraint"

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
			word = params[:word]
			locale = params[:locale]
			raise Discourse::InvalidParameters.new(:word) if word.blank?
			raise Discourse::InvalidParameters.new(:locale) if !LocaleSiteSetting.supported_locales.include?(locale)
			definitions = ::PluginStore.get("discourse_definitions", "definitions") || []
			index = definitions.index { |x| x[:locale] == locale && x[:word] == word }
			raise Discourse::NotFound if index.nil?
			definitions.delete_at index
			::PluginStore.set("discourse_definitions", "definitions", definitions)
			render json: definitions
		end

		def new
			# TODO: Make it so you can edit ones of the same locale
			word = params[:word]
			definition = params[:definition]
			locale = params[:locale] || "en"
			raise Discourse::InvalidParameters.new(:word) if word.blank?
			raise Discourse::InvalidParameters.new(:definition) if definition.blank?
			raise Discourse::InvalidParameters.new(:locale) if !LocaleSiteSetting.supported_locales.include?(locale)
			definitions = ::PluginStore.get("discourse_definitions", "definitions") || []
			definition = { definition: definition, locale: locale, word: word }
			index = definitions.index { |x| x[:locale] == locale && x[:word] == word }
			if index.nil?
				definitions.push(definition)
			else
				definitions[index] = definition
			end
			::PluginStore.set("discourse_definitions", "definitions", definitions)
			render json: definitions
		end
	end

	User.register_custom_field_type("disable_definitions", :boolean)
	DiscoursePluginRegistry.serialized_current_user_fields << "disable_definitions"
	add_to_serializer(:current_user, :disable_definitions) { object.custom_fields["disable_definitions"] }
	register_editable_user_custom_field :disable_definitions

	DiscourseDefinitions::Engine.routes.draw do
		post "/admin/plugins/discourse-definitions" => "discourse_definitions#new", constraints: StaffConstraint.new
		delete "/admin/plugins/discourse-definitions" => "discourse_definitions#delete", constraints: StaffConstraint.new
	end

	Discourse::Application.routes.append do
		get "/admin/plugins/discourse-definitions" => "admin/plugins#index", constraints: StaffConstraint.new
		mount ::DiscourseDefinitions::Engine, at: "/"
	end
end
