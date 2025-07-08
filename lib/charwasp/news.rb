class CharWasP::News < Liquid::Drop
	attr_accessor *%i[title items date datetime]

	def initialize row
		@title = row[:title]
		@date = row[:date]
		@datetime = DateTime.parse @date.gsub '.', '-'
		@items = row[:body].split("\n\n").map do |item|
			item.lines(chomp: true).each_with_object [] do |line, bullet_points|
				if !line.start_with?(?・) && bullet_points.last.is_a?(String)
					line = bullet_points.pop + ' ' + line.strip
				else
					line.sub! /^・/, ''
					line.strip!
				end
				if music_and_chart = CharWasP.db.find_music_and_possibly_chart(line)
					bullet_points.push music_and_chart
					next
				end
				unless line.include? ' ・'
					bullet_points.push line
					next
				end
				bullet_points.concat line.split(/\s+・\s*/).map { CharWasP.db.find_music_and_possibly_chart(_1) || _1 }
			end
		end
	end
end
