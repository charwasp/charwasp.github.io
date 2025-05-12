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
		rendered = template 'music.liquid', src_dir: 'music', music_list: CharWasP.db.each_music.to_a
		write_html 'info/music.html', rendered
	end

	def generate_news
		info 'Generating news list'
		news_list = CharWasP.db.each_news.to_a
		rendered = template 'news.liquid', src_dir: 'news', news_list: news_list
		write_html 'info/news.html', rendered
		rendered = template 'news-rss.liquid', news_list: news_list, site_url: CharWasP.site_url
		write_plain 'info/news-rss.xml', rendered
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
		liquid = @template_cache[path] ||= Liquid::Template.parse File.read File.join 'template', path
		if src_dir
			payload[:scripts] = Dir.glob(File.join 'src', src_dir, '*.js').map { File.read _1 }
			payload[:stylesheets] = Dir.glob(File.join 'src', src_dir, '*.css').map { File.read _1 }
		end
		liquid.render! payload.transform_keys &:to_s
	end

	def write_plain path, content
		path = File.join 'dist', path
		FileUtils.mkdir_p File.dirname path
		File.write path, content
	end

	def write_html path, html
		write_plain path, min_html(html)
	end
end
