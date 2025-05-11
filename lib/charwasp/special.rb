class CharWasP::SpecialStage < Liquid::Drop
	attr_accessor *%i[id phase step hp musics first_of_group]

	def initialize row, first_of_group
		@id = row[:id]
		@phase = row[:phase_number]
		@step = row[:step]
		@hp = row[:required_point]
		@musics = row[:music_id].split(?;).map { CharWasP.db.find_music _1.to_i }
		@first_of_group = first_of_group
	end

	class StepGroup < Liquid::Drop
		attr_accessor *%i[phase steps]

		def initialize phase, steps
			@phase = phase
			@steps = steps
		end
	end

	class Phase < Liquid::Drop
		attr_accessor *%i[phase stages]

		def initialize phase, stages
			@phase = phase
			@stages = stages
		end
	end
end
