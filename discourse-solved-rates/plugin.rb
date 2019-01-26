# name: discourse-solved-rates
# version: 1.0.0
# authors: boyned/Kampfkarren

add_admin_route "discourse_solved_rates.title", "discourse-solved-rates"

after_initialize do
	module ::DiscourseSolvedRates
		class Engine < ::Rails::Engine
			engine_name "discourse_solved_rates"
			isolate_namespace DiscourseSolvedRates
		end

		def self.fix_nan(num)
			num.nan? ? 0 : num
		end

		def self.rate(category, start_date, end_date)
			topics = Topic.where(category_id: category)
				.where("created_at >= ? AND created_at <= ?", start_date, end_date)
			self.fix_nan(topics.select { |topic| !topic.custom_fields["accepted_answer_post_id"].nil? }.count.fdiv(topics.count))
		end

		def self.rate_subcategories(category, start_date, end_data)
			sum = 0
			subcategories = Category.where(parent_category_id: category.id)
			subcategories.each do |subcategory|
				sum += self.rate(subcategory, start_date, end_data)
			end
			sum.fdiv(subcategories.count)
		end
	end

	class DiscourseSolvedRates::DiscourseSolvedRatesController < ::ApplicationController
		def get
			start_date = params[:start_date].to_i
			end_date = params[:end_date].to_i
			category_id = params[:category]
			category = Category.find_by(id: category_id)
			raise Discourse::InvalidParameters.new(:category) unless category
			# TOOD: subcategories
			start_date = Time.at(start_date).to_date.beginning_of_day
			end_date = Time.at(end_date).to_date.end_of_day
			render json: {
				rate: Category.where(parent_category_id: category).count > 0 ?
					DiscourseSolvedRates.rate_subcategories(category, start_date, end_date) :
					DiscourseSolvedRates.rate(category, start_date, end_date)
			}
		end
	end

	require_dependency "staff_constraint"

	DiscourseSolvedRates::Engine.routes.draw do
		post "/admin/plugins/discourse-solved-rates" => "discourse_solved_rates#get", constraints: StaffConstraint.new
	end

	Discourse::Application.routes.append do
		get "/admin/plugins/discourse-solved-rates" => "admin/plugins#index", constraints: StaffConstraint.new
		mount ::DiscourseSolvedRates::Engine, at: "/"
	end
end
