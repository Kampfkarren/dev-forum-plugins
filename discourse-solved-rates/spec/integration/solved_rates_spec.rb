require "rails_helper"

RSpec.describe "Solved Rates" do
	def create_topic_solution(category)
		topic = create_topic(category: category)
		post = create_post(topic: topic)
		DiscourseSolved.accept_answer!(post, Discourse.system_user)
	end

	before do
		SiteSetting.allow_solved_on_all_topics = true
	end

	it "should give the rates on solved threads one category deep" do
		category = Fabricate(:category)

		Topic.where(category_id: category.id).destroy_all
		expect(DiscourseSolvedRates.rate(category, 1.day.ago, Time.now)).to eq(0)

		create_topic_solution(category)
		create_topic(category: category)

		expect(DiscourseSolvedRates.rate(category, 1.day.ago, Time.now)).to eq(0.5)
		freeze_time 2.days.from_now
		expect(DiscourseSolvedRates.rate(category, 1.day.ago, Time.now)).to eq(0)
	end

	it "should give the rates on solved threads inside subcategories" do
		parent_category = Fabricate(:category)
		subcategory1 = Fabricate(:category, parent_category_id: parent_category.id)
		subcategory2 = Fabricate(:category, parent_category_id: parent_category.id)

		Topic.where(category_id: parent_category.id).destroy_all
		Topic.where(category_id: subcategory1.id).destroy_all
		Topic.where(category_id: subcategory2.id).destroy_all

		create_topic_solution(subcategory1)
		create_topic_solution(subcategory2)

		expect(DiscourseSolvedRates.rate_subcategories(parent_category, 1.day.ago, Time.now)).to eq(1)
		freeze_time 2.days.from_now
		expect(DiscourseSolvedRates.rate_subcategories(parent_category, 1.day.ago, Time.now)).to eq(0)
	end

	context "as a staff user" do
		let(:user) { Fabricate(:admin) }

		before do
			sign_in(user)
		end

		it "should give the rates through a web endpoint" do
			category = Fabricate(:category)

			Topic.where(category_id: category.id).destroy_all

			post "/admin/plugins/discourse-solved-rates.json", params: {
				start_date: 1.day.ago.to_time.to_i,
				end_date: Time.now.to_i,
				category: category.id
			}

			expect(response.status).to eq(200)
			expect(JSON.parse(response.body)["rate"]).to eq(0)

			create_topic_solution(category)
			create_topic(category: category)

			post "/admin/plugins/discourse-solved-rates.json", params: {
				start_date: 1.day.ago.to_time.to_i,
				end_date: Time.now.to_i,
				category: category.id
			}

			expect(response.status).to eq(200)
			expect(JSON.parse(response.body)["rate"]).to eq(0.5)

			freeze_time 2.days.from_now

			post "/admin/plugins/discourse-solved-rates.json", params: {
				start_date: 1.day.ago.to_time.to_i,
				end_date: Time.now.to_i,
				category: category.id
			}

			expect(response.status).to eq(200)
			expect(JSON.parse(response.body)["rate"]).to eq(0)
		end

		it "should give subcategory rates through a web endpoint" do
			parent_category = Fabricate(:category)
			subcategory1 = Fabricate(:category, parent_category_id: parent_category.id)
			subcategory2 = Fabricate(:category, parent_category_id: parent_category.id)

			Topic.where(category_id: parent_category.id).destroy_all
			Topic.where(category_id: subcategory1.id).destroy_all
			Topic.where(category_id: subcategory2.id).destroy_all

			create_topic_solution(subcategory1)
			create_topic_solution(subcategory2)

			post "/admin/plugins/discourse-solved-rates.json", params: {
				start_date: 1.day.ago.to_time.to_i,
				end_date: Time.now.to_i,
				category: parent_category.id
			}

			expect(response.status).to eq(200)
			expect(JSON.parse(response.body)["rate"]).to eq(1)

			freeze_time 2.days.from_now

			post "/admin/plugins/discourse-solved-rates.json", params: {
				start_date: 1.day.ago.to_time.to_i,
				end_date: Time.now.to_i,
				category: parent_category.id
			}

			expect(response.status).to eq(200)
			expect(JSON.parse(response.body)["rate"]).to eq(0)
		end
	end

	context "as a normal user" do
		let(:user) { Fabricate(:user) }

		before do
			sign_in(user)
		end

		it "should error when trying to get rates" do
			category = Fabricate(:category)

			post "/admin/plugins/discourse-solved-rates.json", params: {
				start_date: 1.day.ago.to_time.to_i,
				end_date: Time.now.to_i,
				category: category.id
			}

			expect(response.status).to eq(404)
		end
	end
end
