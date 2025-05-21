class CharWasP::Chart < Liquid::Drop
	COLORS = {
		easy: [0x00, 0x41, 0xe9],
		normal: [0xe9, 0x6e, 0x00],
		hard: [0xe9, 0x00, 0x2e],
		extra: [0xe9, 0x00, 0xad],
		extra_plus: [0xe9, 0x00, 0xad],
		chaos: [0x4b, 0x4b, 0x9d],
		chaos_plus: [0x4b, 0x4b, 0x9d],
	}

	attr_accessor *%i[music difficulty_id id difficulty level price]

	def initialize music, difficulty_id, id, difficulty, level, price
		@music = music
		@difficulty_id = difficulty_id
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
				next "Clear <a class=\"course\" href=\"{{ base }}/info/course/#{course.id}.html\">#{CGI.escapeHTML course.full_name}</a>"
			end
			count = unlock[:count] == 1 ? "1 chart of" : "#{unlock[:count]} charts of"
			music = if unlock[:music] != :any
				m = unlock[:music]
				"<a class=\"music#{" chaos" if m.chaos}\" href=\"{{ base }}/info/music/#{m.id}.html\">#{CGI.escapeHTML m.name}</a>"
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

	def to_actual
		@actual ||= CharWasP.db.find_actual_chart @id
	end

	# NOTE: Only available after to_actual is called once
	def note_count
		@actual&.notes&.size
	end

	def color
		COLORS[@difficulty]
	end
end

class CharWasP::ActualChart
	attr_reader *%i[notes bpm_changes speed_changes events offset]

	def initialize cbt
		@cbt = cbt
		read_events
		process_bpm_changes
		process_speed_changes
		process_notes
		read_offset
	end

	def read_events
		@events = @cbt[:notes].map do |event|
			measure, track_count, subdivision_count, track_index, subdivision_index, type, *args = event
			{
				beat: (measure + subdivision_index.quo(subdivision_count)) * 4,
				track_count:,
				track_index:,
				type: {
					1  => :music,
					2  => :bpm_change,
					3  => :speed,
					10 => :tap,
					20 => :hold_begin,
					21 => :hold_end,
					22 => :hold_middle,
					30 => :drag_begin,
					31 => :drag_middle,
					32 => :drag_end,
					40 => :wide_tap,
					50 => :wide_hold_begin,
					51 => :wide_hold_end,
				}[type],
				args:,
			}
		end
		@events.sort_by! { _1[:beat] }

		@bpm_changes = []
		@speed_changes = []
		@notes = []

		@events.each do |event|
			case event[:type]
			when :bpm_change
				@bpm_changes.push event
			when :speed
				@speed_changes.push event
			when :music
			else
				@notes.push event
			end
		end
	end

	def calculate_delta_beats events
		events.first&.[]= :delta_beat, events.first[:beat]
		events.each_cons(2) { _2[:delta_beat] = _2[:beat] - _1[:beat] }
	end

	def process_bpm_changes
		@initial_bpm = @cbt[:info][:bpm]
		@bpm_changes.each { _1[:bpm] = _1[:args].first }
		@bpm_changes = @bpm_changes.chunk { _1[:bpm] }.map { _2.first } # Some charts have many duplicate BPM changes
		calculate_delta_beats @bpm_changes
	end

	def process_speed_changes
		@initial_speed = 1.0
		@speed_changes.each { _1[:speed] = _1[:args].first }
		calculate_delta_beats @speed_changes
	end

	DRAG_TYPES = %i[drag_begin drag_middle drag_end].to_set
	GROUPED_TYPES = %i[hold_begin hold_end hold_middle wide_hold_begin wide_hold_end drag_begin drag_middle drag_end].to_set
	WIDE_TYPES = %i[wide_tap wide_hold_begin wide_hold_end].to_set

	def process_notes
		@notes.each do |note|
			note[:width] = WIDE_TYPES.include?(note[:type]) ? note[:args].last : 0.0
			note[:width] *= -1 if DRAG_TYPES.include? note[:type]
			note[:group] = note[:args].first if GROUPED_TYPES.include? note[:type]
		end
		@notes.each_with_index.group_by { |note, index| note[:group] }.each do |group, notes_and_indices|
			next unless group
			notes_and_indices.each_cons(2) { |(note1, index1), (note2, index2)| note1[:next] = index2 - index1 }
		end
		@notes.each { _1[:next] ||= 0 }
		calculate_delta_beats @notes
	end

	def read_offset
		@offset = -time_at(@events.find { _1[:type] == :music }[:beat])
	end

	def time_at beat
		bpm = @initial_bpm.to_f
		last_beat = 0
		time = 0.0
		@bpm_changes.each do |event|
			break if event[:beat] > beat
			time += event[:delta_beat] / bpm
			bpm = event[:bpm].to_f
			last_beat = event[:beat]
		end
		time += (beat - last_beat) / bpm
		time * 60
	end

	def write io
		pos = io.tell

		io.write 'CWPC' # magic
		io.write [1].pack 'C' # version
		io.write Base64.decode64 'bWF0c3U0NTEyAA==' # charter
		io.write Base64.decode64 'RnJvbSBDaGFpbkJlZVQA' # comments
		io.write [@offset].pack 'E' # offset

		# BPM list
		io.write [@bpm_changes.size, @initial_bpm/60.0].pack 'L<E'
		@bpm_changes.each do |event|
			delta_beat = event[:delta_beat]
			io.write [delta_beat.numerator, delta_beat.denominator, event[:bpm]/60.0].pack 'L<L<E'
		end
		
		# Speed list
		io.write [@speed_changes.size, @initial_speed].pack 'L<E'
		@speed_changes.each do |event|
			delta_beat = event[:delta_beat]
			io.write [delta_beat.numerator, delta_beat.denominator, event[:speed]].pack 'L<L<E'
		end

		# Notes list
		io.write [@notes.size].pack 'L<'
		@notes.each do |note|
			delta_beat = note[:delta_beat]
			io.write [
				delta_beat.numerator,
				delta_beat.denominator,
				note[:track_count],
				note[:track_index],
				note[:next],
				note[:width],
			].pack 'L<L<S<S<L<e'
		end

		io.tell - pos
	end
end
