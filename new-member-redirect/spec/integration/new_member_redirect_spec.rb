require "rails_helper"

RSpec.describe "New Member Redirect" do
	let(:bulletin_board) { Fabricate(:category) }
	let(:engine_feedback) { Fabricate(:category) }
	let(:feature_requests) { Fabricate(:category, parent_category_id: engine_feedback.id) }
	let(:random_category) { Fabricate(:category) }

	let(:lead_top_contributors) { Fabricate(:group, name: "Lead_Top_Contributor") }
	let(:lead_top_contributor) {
		user = Fabricate(:user)
		lead_top_contributors.add(user)
		user
	}

	before do
		SiteSetting.new_member_prohibited_category = engine_feedback.id
		SiteSetting.new_member_redirect_to = bulletin_board.id
		SiteSetting.lead_top_contributors = lead_top_contributors.name
	end

	context "as a new member" do
		let(:user) { Fabricate(:user, trust_level: 1) }

		it "should let you post on random categories that you would have access to otherwise" do
			creator = PostCreator.new(user,
										title: "This is a cool random category",
										raw: "Can't wait to post",
										category: random_category.id)
			post = creator.create
			expect(post.valid?).to eq(true)
			expect(post.topic.category.id).to eq(random_category.id)
		end

		it "should redirect your posts to prohibited categories to bulletin board and pm" do
			# No lead top contributors messages yet
			expect(TopicQuery.new(nil, group_name: lead_top_contributors.name)
					.list_private_messages_group(lead_top_contributor)
					.topics.length).to eq(0)

			creator = PostCreator.new(user,
				title: "I have a feature request",
				raw: "We should bring back Tix",
				category: feature_requests.id)
			post = creator.create
			expect(post.valid?).to eq(true)
			expect(post.topic.category.id).to eq(bulletin_board.id)

			messages = TopicQuery.new(nil, group_name: lead_top_contributors.name)
					.list_private_messages_group(lead_top_contributor)
					.topics
			expect(messages.length).to eq(1)
			expect(messages[0].posts.first.raw).to include("/t/" + post.topic.slug)
		end
	end

	context "as a member" do
		let(:user) { Fabricate(:user, trust_level: 2) }

		it "should let you post on random categories that you would have access to otherwise" do
			creator = PostCreator.new(user,
										title: "This is a cool random category",
										raw: "Can't wait to post",
										category: random_category.id)
			post = creator.create
			expect(post.valid?).to eq(true)
			expect(post.topic.category.id).to eq(random_category.id)
		end

		it "should not redirect your posts to prohibited categories" do
			creator = PostCreator.new(user,
				title: "I have a feature request",
				raw: "We should bring back Tix",
				category: feature_requests.id)
			post = creator.create
			expect(post.valid?).to eq(true)
			expect(post.topic.category.id).to eq(feature_requests.id)
		end
	end
end
