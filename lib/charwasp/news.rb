class CharWasP::News < Liquid::Drop
	FIELDS = %i[title items date datetime]
	attr_accessor *FIELDS

	def initialize row
		@title = row[:title]
		@date = row[:date]
		@datetime = DateTime.parse @date.gsub '.', '-'
		@items = row[:body].split("\n\n").map do |item|
			item.lines(chomp: true).map do |line|
				next line unless line.start_with? ?・
				line.sub!(/^・/, '')
				CharWasP.db.find_music(line) || line
			end
		end
	end

	def before_method meth
		FIELDS.include?(meth) ? send(meth) : super
	end
end
