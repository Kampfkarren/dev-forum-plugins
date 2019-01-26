require "rails_helper"

RSpec.describe "Dev Rel Automated Messages" do
	let(:dev_rel) { Fabricate(:group, name: "DevRelationsTeam") }

	before do
		5.times do |i|
			dev_rel.add(Fabricate(:user, username: "DevRel" + i.to_s))
		end
	end

	it "should send messages from dev rel instead of system" do
		captured = [false, false, false, false, false]
		5.times do
			user = Discourse.site_contact_user
			expect(dev_rel.user_ids).to include(user.id)
			dev_rel.remove user
			captured[user.username[-1].to_i] = true
		end
		expect(captured).not_to include(false)
	end
end
