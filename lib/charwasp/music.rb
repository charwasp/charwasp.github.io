class CharWasP::MusicBasic < Liquid::Drop
	DIFFICULTIES = %i[easy normal hard extra extra_plus]
	CHAOS_DIFFICULTIES = %i[chaos chaos_plus]

	attr_accessor *%i[id name artist bgm preview keywords chaos boost charts inst vocal]

	def initialize row
		@id = row[:id]
		@preview = File.join CharWasP.package_url, "Preview/preview_#@id.ogg"
		@name = row[:name]
		@artist = row[:artist]
		@bgm = File.join CharWasP.package_url, row[:file]
		@chaos = row[:chaos] != 0
		@charts = (@chaos ? CHAOS_DIFFICULTIES : DIFFICULTIES).map.with_index do |difficulty, i|
			level = row[:"level_#{i+1}"]
			id = row[:"note_id_#{i+1}"]
			price = row[:"require_point_#{i+1}"]
			level == 0 ? nil : CharWasP::Chart.new(self, id, difficulty, level, price)
		end.compact
		@keywords = row[:keyword].split(?\t).reject &:empty?
		categories = row[:category]
		@inst = categories & 4 > 0
		@vocal = categories & 8 > 0
		@boost = row[:pickup] != 0
	end
end

class CharWasP::Music < CharWasP::MusicBasic
	DIFFICULTIES = %i[easy normal hard extra extra_plus]
	CHAOS_DIFFICULTIES = %i[chaos chaos_plus]

	attr_accessor *%i[secret chaos_version non_chaos_version special_stages unknown_stage]

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
	end
end
