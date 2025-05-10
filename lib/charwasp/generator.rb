class CharWasP::Generator
	include CharWasP::Logger

	def generate
		generate_public
		generate_music
		generate_news
		generate_music_details
	end

	def generate_public
		info 'Generating hardcoded pages'
		FileUtils.rm_r 'dist' if Dir.exist? 'dist'
		FileUtils.cp_r 'public', 'dist'
	end

	def generate_music
		info 'Generating music list'
		rendered = template 'music.liquid', src_dir: 'music', music_list: CharWasP.db.each_music.to_a
		write_html 'info/music.html', rendered
	end

	def generate_news
		info 'Generating news list'
		rendered = template 'news.liquid', src_dir: 'news', news_list: CharWasP.db.each_news.to_a
		write_html 'info/news.html', rendered
	end

	def generate_music_details
		info 'Generating music details'
		CharWasP.db.each_music do |music|
			rendered = template 'music-details.liquid', src_dir: 'music-details', music: music
			write_html "info/music/#{music.id}.html", rendered
		end
	end

	def template path, src_dir: nil, **payload
		liquid = Liquid::Template.parse File.read File.join 'template', path
		if src_dir
			payload[:scripts] = Dir.glob(File.join 'src', src_dir, '*.js').map { File.read _1 }
			payload[:stylesheets] = Dir.glob(File.join 'src', src_dir, '*.css').map { File.read _1 }
		end
		liquid.render! payload.transform_keys &:to_s
	end

	def write_html path, html
		path = File.join 'dist', path
		FileUtils.mkdir_p File.dirname path
		html = minify_html html, minify_css: true, minify_js: true
		File.write path, html
	end
end
