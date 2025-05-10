class CharWasP::Music < Liquid::Drop
	DIFFICULTIES = %i[easy normal hard extra extra_plus]
	CHAOS_DIFFICULTIES = %i[chaos chaos_plus]

	FIELDS = %i[
		id name artist bgm preview keywords chaos boost charts inst vocal
		secret chaos_version non_chaos_version
	]
	attr_accessor *FIELDS

	def initialize row
		@id = row[:id]
		@preview = CharWasP.package_url + "Preview/preview_#@id.ogg"
		@name = row[:name]
		@artist = row[:artist]
		@bgm = CharWasP.package_url + row[:file]
		@chaos = row[:chaos] != 0
		@charts = (@chaos ? CHAOS_DIFFICULTIES : DIFFICULTIES).map.with_index do |difficulty, i|
			level = row[:"level_#{i+1}"]
			id = row[:"note_id_#{i+1}"]
			price = row[:"require_point_#{i+1}"]
			level == 0 ? nil : CharWasP::Chart.new(id, difficulty, level, price)
		end.compact
		@keywords = row[:keyword].split(?\t).reject &:empty?
		categories = row[:category]
		@inst = categories & 4 > 0
		@vocal = categories & 8 > 0
		@boost = row[:pickup] != 0
		@secret = CharWasP.db.secrets.include? @id
		if CharWasP.db.has_chaos[@id]
			@chaos_version = CharWasP.db.has_chaos[@id]
		elsif CharWasP.db.has_non_chaos[@id]
			@non_chaos_version = CharWasP.db.has_non_chaos[@id]
		end
	end

	def before_method meth
		FIELDS.include?(meth) ? send(meth) : super
	end
end
