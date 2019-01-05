require "rails_helper"

RSpec.describe "Discourse Definitions" do
	let(:valid_definition) { {
		word: "Doge",
		definition: "A hillarious dog",
		locale: "en",
	} }

	let(:changed_definition) { {
		word: "Doge",
		definition: "An amazingly funny dog",
		locale: "en",
	} }

	context "as a normal user" do
		before do
			sign_in(Fabricate(:user))
		end

		it "should not let you mess with definitions as a normal user" do
			post "/admin/plugins/discourse-definitions.json", params: valid_definition
			expect(response.status).to eq(404)
			delete "/admin/plugins/discourse-definitions.json", params: valid_definition
			expect(response.status).to eq(404)
		end
	end

	context "as a staff user" do
		before do
			sign_in(Fabricate(:admin))
		end

		it "should let you create, edit, and delete definitions" do
			expect(PluginStore.get("discourse_definitions", "definitions")).to eq(nil)

			# New definition
			post "/admin/plugins/discourse-definitions.json", params: valid_definition
			expect(response.status).to eq(200)
			expect(PluginStore.get("discourse_definitions", "definitions")).to eq([valid_definition.stringify_keys])

			# Edit definition
			post "/admin/plugins/discourse-definitions.json", params: changed_definition
			expect(response.status).to eq(200)
			expect(PluginStore.get("discourse_definitions", "definitions")).to eq([changed_definition.stringify_keys])

			# Delete definition
			delete "/admin/plugins/discourse-definitions.json", params: { word: valid_definition[:word], locale: valid_definition[:locale] }
			expect(response.status).to eq(200)
			expect(PluginStore.get("discourse_definitions", "definitions")).to eq([])
		end
	end
end
