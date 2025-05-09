class CharWasP::Chart < Liquid::Drop
	FIELDS = %i[id difficulty level price]
	attr_accessor *FIELDS

	def initialize id, difficulty, level, price
		@id = id
		@difficulty = difficulty
		@level = level
		@price = price
	end

	def before_method meth
		FIELDS.include?(meth) ? send(meth) : super
	end
end
