require "rails_helper"

RSpec.describe "TL2 Promotion Message" do
	it "should send a message when you promote to tl2" do
		user = Fabricate(:user, trust_level: 1)
		promotion = Promotion.new(user)
		expect(user.trust_level).to eq(1)
		expect(Jobs::SendSystemMessage.jobs.size).to eq(0)
		promotion.change_trust_level!(TrustLevel[2])
		expect(user.trust_level).to eq(2)
		expect(Jobs::SendSystemMessage.jobs.size).to eq(1)
	end
end
