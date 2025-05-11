class CharWasP::Course < Liquid::Drop
	attr_accessor *%i[id name sub_name full_name charts reward gauge level]

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

	class Version < Liquid::Drop
		attr_accessor *%i[name courses]

		def initialize name, courses
			@name = name
			@courses = courses
		end
	end
end
