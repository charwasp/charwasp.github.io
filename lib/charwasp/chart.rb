class CharWasP::Chart < Liquid::Drop
	attr_accessor *%i[music id difficulty level price]

	def initialize music, id, difficulty, level, price
		@music = music
		@id = id
		@difficulty = difficulty
		@level = level
		@price = price
	end

	def difficulty_range_text range, chaos
		return 'any difficulty' if range == (0..4)
		first, last = [range.first, range.last].map do |difficulty|
			name = (chaos ? CharWasP::Music::CHAOS_DIFFICULTIES : CharWasP::Music::DIFFICULTIES)[difficulty].to_s
			"<span class=\"difficulty #{name.gsub ?_, ?-}\">#{name.gsub '_plus', ?+}</span>"
		end
		first == last ? first : "#{first}&ndash;#{last}"
	end

	def level_range_text range
		return 'any level' if range == (1..13)
		first, last = [range.first, range.last].map do |level|
			"<span class=\"level\">#{level}</span>"
		end
		first == last ? "level #{first}" : "level #{first}&ndash;#{last}"
	end

	def unlock_conditions
		return ["<span class=\"coin\">#@price</span>"] if @price > 0
		return ["Free"] if (unlocks = CharWasP.db.unlocks[@id]).empty?
		unlocks.map do |unlock|
			if unlock[:music].is_a? CharWasP::Course
				course = unlock[:music]
				next "Clear <a class=\"course\" href=\"#{CharWasP.site_url}/info/course/#{course.id}.html\">#{course.full_name}</a>"
			end
			count = unlock[:count] == 1 ? "1 chart of" : "#{unlock[:count]} charts of"
			music = if unlock[:music] != :any
				m = unlock[:music]
				"<a class=\"music#{" chaos" if m.chaos}\" href=\"#{CharWasP.site_url}/info/music/#{m.id}.html\">#{m.name}</a>"
			end
			range = case unlock[:range_type]
			when :difficulty
				difficulty_range_text unlock[:range], unlock[:music].is_a?(CharWasP::MusicBasic) && unlock[:music].chaos
			when :level
				level_range_text unlock[:range]
			end
			requirement = case unlock[:requirement_type]
			when :play
				'Play'
			when :rank
				"Achieve <span class=\"rank #{unlock[:requirement].downcase.sub ?+, '-plus'}\">#{unlock[:requirement]}</span> on"
			when :state
				"<span class=\"state #{unlock[:requirement].downcase}\">#{unlock[:requirement]}</span>"
			end
			[requirement, count, music, range].compact.join(' ')
		end
	end
end
