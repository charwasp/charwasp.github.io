class CharWasP::News < Liquid::Drop
	attr_accessor *%i[title items date datetime]

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
end
