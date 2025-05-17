class CharWasP::Generator
	include CharWasP::Logger
	include CharWasP::Minifier

	def initialize
		@template_cache = {}
	end

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
		Dir.glob 'dist/**/*' do |path|
			if path.end_with? '.js'
				File.write path, min_js(File.read path)
			elsif path.end_with? '.css'
				File.write path, min_css(File.read path)
			elsif path.end_with? '.html'
				File.write path, min_html(File.read path)
			elsif path.end_with? '.svg'
				File.write path, min_svg(File.read path)
			end
		end
	end

	def generate_signature
		File.write 'dist/master.zip.sig', CharWasP.assets['master.zip'][:md5]
	end

	def generate_music
		info 'Generating music list'
		music_list = CharWasP.db.each_music.to_a
		write_html 'music', 'info/music.html', src_dir: 'music', music_list:
	end

	def generate_news
		info 'Generating news list'
		news_list = CharWasP.db.each_news.to_a
		write_html('news', 'info/news.html', src_dir: 'news', news_list:)
		write_plain 'news-rss', 'info/news-rss.xml', news_list:
	end

	def generate_music_details
		info 'Generating music details'
		FileUtils.mkdir_p 'dist/info/cwp-music'
		CharWasP.db.each_music.with_progress(total: CharWasP.db.music_count).each do |music|
			music.load_actual_charts
			File.open("dist/info/cwp-music/#{music.id}.cwpm", 'wb') { music.write _1 }
			write_html 'music-details', "info/music/#{music.id}.html", music:
		end
	end

	def generate_course
		info 'Generating course list'
		course_versions = CharWasP.db.each_course.group_by(&:sub_name).map do |name, courses|
			CharWasP::Course::Version.new name, courses
		end
		write_html 'course', 'info/course.html', src_dir: 'course', course_versions:
	end

	def generate_course_details
		info 'Generating course details'
		CharWasP.db.each_course do |course|
			write_html 'course-details', "info/course/#{course.id}.html", course:
		end
	end

	def generate_special
		info 'Generating special stages'
		phases = CharWasP.db.each_special_stage.group_by(&:phase).map do |phase, stages|
			CharWasP::SpecialStage::Phase.new phase, stages
		end
		write_html 'special', 'info/special.html', src_dir: 'special', phases:
	end

	def template path, src_dir: nil, **payload
		liquid = @template_cache[path] ||= Liquid::Template.parse File.read File.join 'template', path + '.liquid'
		if src_dir
			payload[:scripts] = Dir.glob(File.join 'src', src_dir, '*.js').map { File.read _1 }
			payload[:stylesheets] = Dir.glob(File.join 'src', src_dir, '*.css').map { File.read _1 }
		end
		payload[:site_url] = CharWasP.site_url
		liquid.render! payload.transform_keys &:to_s
	end

	def write_plain template_path, path, **payload
		content = template template_path, base: base(path), **payload
		write path, content
	end

	def write_html template_path, path, **payload
		content = min_html template template_path, base: base(path), **payload
		write path, content
	end

	def write path, content
		path = File.join 'dist', path
		FileUtils.mkdir_p File.dirname path
		File.write path, content
	end

	def base path
		n = path.count ?/
		n.zero? ? '.' : Array.new(n, '..').join(?/)
	end
end
