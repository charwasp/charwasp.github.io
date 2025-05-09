class CharWasP::Generator
	def generate
		generate_public
		generate_music
	end

	def generate_public
		FileUtils.rm_r 'dist' if Dir.exist? 'dist'
		FileUtils.cp_r 'public', 'dist'
	end

	def generate_music
		rendered = template 'music.liquid', music_list: CharWasP.db.each_music.to_a
		write_html 'info/music.html', rendered
	end

	def template path, **payload
		liquid = Liquid::Template.parse File.read File.join 'template', path
		liquid.render! payload.transform_keys &:to_s
	end

	def write_html path, html
		path = File.join 'dist', path
		FileUtils.mkdir_p File.dirname path
		html = minify_html html, minify_css: true, minify_js: true
		File.write path, html
	end
end
