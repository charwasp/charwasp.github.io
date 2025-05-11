class CharWasP::Generator
	include CharWasP::Logger

	def generate
		generate_public
		generate_signature
		generate_music
		generate_news
		generate_music_details
		generate_course
		generate_course_details
		generate_special
	end

	def generate_public
		info 'Generating hardcoded pages'
		FileUtils.rm_r 'dist' if Dir.exist? 'dist'
		FileUtils.cp_r 'public', 'dist'
	end

	def generate_signature
		File.write 'dist/master.zip.sig', CharWasP.assets['master.zip'][:md5]
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

	def generate_course
		info 'Generating course list'
		course_versions = CharWasP.db.each_course.group_by(&:sub_name).map do |name, courses|
			CharWasP::Course::Version.new name, courses
		end
		rendered = template 'course.liquid', src_dir: 'course', course_versions: course_versions
		write_html 'info/course.html', rendered
	end

	def generate_course_details
		info 'Generating course details'
		CharWasP.db.each_course do |course|
			rendered = template 'course-details.liquid', course: course
			write_html "info/course/#{course.id}.html", rendered
		end
	end

	def generate_special
		info 'Generating special stages'
		phases = CharWasP.db.each_special_stage.group_by(&:phase).map do |phase, stages|
			CharWasP::SpecialStage::Phase.new phase, stages
		end
		rendered = template 'special.liquid', src_dir: 'special', phases: phases
		write_html 'info/special.html', rendered
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
