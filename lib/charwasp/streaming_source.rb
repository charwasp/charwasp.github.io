class CharWasP::StreamingSource
	class Basic < Liquid::Drop
		attr_reader :id

		def initialize data
			@id = data['id']
		end

		def self.search query, duration
		end

		def type
		end

		def url
		end

		def embed_url
		end

		def json_data
			{ type:, id: }
		end

		def to_json *args
			{ JSON.create_id => CharWasP::StreamingSource.name, **json_data }.to_json *args
		end
	end

	class YouTube < Basic
		@uri = URI "https://#{ENV['INVIDIOUS_HOST']}/api/v1/search" if ENV['INVIDIOUS_HOST']

		def initialize data
			super
			@time = data['time']
		end

		def url
			"https://youtu.be/#@id" + (@time ? "?t=#@time" : '')
		end

		def embed_url
			"https://youtube.com/embed/#@id?autoplay=0" + (@time ? "&start=#@time" : '')
		end

		def json_data
			@time ? super.merge(time: @time) : super
		end

		def self.search q, duration
			return unless @uri
			@uri.query = URI.encode_www_form({ q:, type: 'video' })
			res = Net::HTTP.start @uri.host, @uri.port, use_ssl: true do |http|
				req = Net::HTTP::Get.new @uri
				req['Accept'] = 'application/json; charset=utf-8'
				http.request req
			end
			unless res.is_a? Net::HTTPSuccess
				warn "Invidious API error: #{res.code} #{res.message}"
				return
			end
			JSON.parse(res.body, symbolize_names: true).take(5).each do |video|
				next unless video[:type] == 'video'
				puts "#{video[:videoId]} #{video[:title]}"
				title = video[:title].gsub(/\s/, '').downcase
				next if %w[fc allperfect fullcombo].any? { title.include?(_1) && !q.include?(_1) }
				return new 'id'=>video[:videoId] if video[:lengthSeconds] >= duration - 3
			end
			nil
		end
	end

	class SoundCloud < Basic
		attr_reader :url

		def initialize data
			super
			@url = data['url']
		end

		def embed_url
			"https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/#@id&auto_play=false&hide_related=true&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=true"
		end

		def json_data
			super.merge url:
		end

		def self.search q, duration
			@token ||= ENV['SOUNDCLOUD_OAUTH_TOKEN']
			return unless @token
			uri = URI 'https://api-v2.soundcloud.com/search'
			uri.query = URI.encode_www_form({ q: })
			res = Net::HTTP.start uri.host, uri.port, use_ssl: true do |http|
				req = Net::HTTP::Get.new uri
				req['Authorization'] = "OAuth #@token"
				req['Accept'] = 'application/json; charset=utf-8'
				http.request req
			end
			unless res.is_a? Net::HTTPSuccess
				warn "SoundCloud API error: #{res.code} #{res.message}"
				return
			end
			JSON.parse(res.body, symbolize_names: true)[:collection].take(3).each do |track|
				next unless track[:kind] == 'track'
				return new 'id'=>track[:id], 'url'=>track[:permalink_url] if track[:duration] / 1000.0 >= duration - 3
			end
			nil
		end
	end

	class BandCamp < Basic
		attr_reader :url

		def initialize data
			super
			@url = data['url']
		end

		def embed_url
			"https://bandcamp.com/EmbeddedPlayer/size=large/tracklist=false/artwork=small/track=#@id"
		end

		def json_data
			super.merge url:
		end

		def self.search q, duration
			nil # TODO
		end
	end

	CLASSES = {
		youtube: YouTube,
		soundcloud: SoundCloud,
		bandcamp: BandCamp,
	}

	def self.find *args, **opts
		CLASSES.each do |type, klass|
			source = klass.search *args, **opts
			return source if source
		end
		nil
	end

	def self.json_create obj
		CLASSES[obj['type'].to_sym]&.new obj
	end

	CLASSES.each do |type, klass|
		klass.define_method(:type) { type }
	end
end
