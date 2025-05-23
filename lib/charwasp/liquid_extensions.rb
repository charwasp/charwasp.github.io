module CharWasP::LiquidFilters
	def liquify input
		Liquid::Template.parse(Liquid::Utils.to_s(input), environment: @context.environment).render @context
	end
end

Liquid::Environment.default.register_filter CharWasP::LiquidFilters
