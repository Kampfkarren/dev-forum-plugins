# name: tl2-promotion-message
# version: 1.0.0
# authors: boyned/Kampfkarren

after_initialize do
	module TL2PromotionMessage
		def change_trust_level!(level, opts = {})
			if level == TrustLevel[2] then
				Jobs.enqueue(
					:send_system_message,
					user_id: @user.id,
					message_type: "welcome_tl2_user",
				)
			end

			super(level, opts)
		end
	end

	Promotion.send(:prepend, TL2PromotionMessage)
end
