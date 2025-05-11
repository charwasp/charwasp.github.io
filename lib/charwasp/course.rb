class CharWasP::Course < Liquid::Drop
	FIELDS = %i[id name sub_name full_name charts reward gauge level]
	attr_accessor *FIELDS

	def initialize row
		@id = row[:id]
		@name = row[:name]
		@sub_name = row[:sub_name]
		@full_name = "#@sub_name #@name"
		@charts = (1..4).map { CharWasP.db.find_chart row[:"music#{_1}"] }
		@reward = row[:point]
		@gauge = row[:gauge_level]
		@level = @id / 10000 % 100 - 10
	end

	def before_method meth
		FIELDS.include?(meth) ? send(meth) : super
	end

	class Version < Liquid::Drop
		FIELDS = %i[name courses]
		attr_accessor *FIELDS

		def initialize name, courses
			@name = name
			@courses = courses
		end

		def before_method meth
			FIELDS.include?(meth) ? send(meth) : super
		end
	end
end
