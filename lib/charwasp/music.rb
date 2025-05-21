class CharWasP::MusicBasic < Liquid::Drop
	DIFFICULTIES = %i[easy normal hard extra extra_plus]
	CHAOS_DIFFICULTIES = %i[chaos chaos_plus]

	attr_accessor *%i[
		id name artist
		bgm_relative bgm bgm_hash preview_relative preview preview_hash
		keywords chaos boost charts inst vocal
	]

	def initialize row
		@id = row[:id]
		@preview_relative = "Preview/preview_#@id.ogg"
		@preview = File.join CharWasP.package_url, @preview_relative
		@preview_hash = row[:preview_hash]
		@name = row[:name]
		@artist = row[:artist]
		@bgm_relative = row[:file]
		@bgm = File.join CharWasP.package_url, @bgm_relative
		@bgm_hash = row[:hash]
		@chaos = row[:chaos] != 0
		@charts = (@chaos ? CHAOS_DIFFICULTIES : DIFFICULTIES).map.with_index do |difficulty, i|
			level = row[:"level_#{i+1}"]
			id = row[:"note_id_#{i+1}"]
			price = row[:"require_point_#{i+1}"]
			level == 0 ? nil : CharWasP::Chart.new(self, i, id, difficulty, level, price)
		end.compact
		@keywords = row[:keyword].split(?\t).reject &:empty?
		@categories = row[:category]
		@inst = @categories & 4 > 0
		@vocal = @categories & 8 > 0
		@boost = row[:pickup] != 0
	end
end

class CharWasP::Music < CharWasP::MusicBasic
	DIFFICULTIES = %i[easy normal hard extra extra_plus]
	CHAOS_DIFFICULTIES = %i[chaos chaos_plus]

	attr_accessor *%i[
		secret chaos_version non_chaos_version special_stages unknown_stage
		duration streaming_source
	]

	def initialize row
		super row
		@secret = CharWasP.db.secrets.include? @id
		if CharWasP.db.has_chaos[@id]
			@chaos_version = CharWasP.db.has_chaos[@id]
		elsif CharWasP.db.has_non_chaos[@id]
			@non_chaos_version = CharWasP.db.has_non_chaos[@id]
		end
		@special_stages = CharWasP.db.special_stages[@id]
		@unknown_stage = CharWasP.db.unknown_stages[@id]
		@duration = CharWasP.db.durations[@id]
		@streaming_source = CharWasP.db.streaming_sources[@id]
	end

	def load_actual_charts
		@actual_charts = @charts.map &:to_actual
	end

	def write io
		pos = io.tell

		io.write 'CWPM'
		io.write [1].pack 'C' # version
		io.write @name, ?\0
		io.write @artist, ?\0
		io.write [@categories].pack 'C'
		io.write [2].pack 'C' # music type: URL
		io.write 'https://corsproxy.io/?url=', @bgm, ?\0
		io.write [2].pack 'C' # preview type: URL
		io.write 'https://corsproxy.io/?url=', @preview, ?\0
		io.write [0].pack 'C' # cover type: none
		io.write [@keywords.size].pack 'C'
		@keywords.each { io.write _1, ?\0 }

		io.write [@charts.size].pack 'C'
		chart_offsets = @charts.map do |chart|
			io.write chart.difficulty.to_s.sub('_plus', ?+).upcase, ?\0
			io.write chart.color.pack 'CCC'
			io.write chart.level.to_s, ?\0
			io.write [chart.level * 1000].pack 'L<'
			io.write [0, 0].pack 'Q<Q<' # placeholder for offset and length
			io.tell
		end
		@actual_charts.zip chart_offsets do |actual_chart, offset|
			pos = io.tell
			length = actual_chart.write io
			io.seek offset - 16
			io.write [pos, length].pack 'Q<Q<'
			io.seek pos + length
		end
	end
end
