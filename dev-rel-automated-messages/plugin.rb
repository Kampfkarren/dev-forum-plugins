# name: dev-rel-automated-messages
# version: 1.0.0
# authors: boyned/Kampfkarren

after_initialize do
	Discourse.module_eval do
		def self.site_contact_user
			puts "i shit my pants"
			Group.find_by(name: "DevRelationsTeam").users.sample
		end
	end
end
