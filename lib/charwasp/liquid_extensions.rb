module CharWasP::LiquidFilters
	def liquify input
		Liquid::Template.parse(Liquid::Utils.to_s input).render @context
	end
end

Liquid::Template.register_filter CharWasP::LiquidFilters
