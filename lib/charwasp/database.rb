class CharWasP::Database
	include CharWasP::Logger

	attr_reader :secrets, :has_chaos, :has_non_chaos
	attr_reader :special_stages, :unlocks, :unknowns

	def init
		init_params
		download_and_unzip_if_needed
		init_db
		init_secrets
		init_has_chaos
		init_unlocks
	end

	def init_params
		@asset_key = 'master.zip'
		@download_url = CharWasP.package_url + @asset_key
		@download_path = File.join 'download', @asset_key
		@download_md5 = CharWasP.assets[@asset_key][:md5]
		@unzip_file = 'master.db'
		@unzip_path = File.join 'download', @unzip_file
	end

	def downloaded_md5
		if File.exist? @download_path
			Digest::MD5.file(@download_path).hexdigest
		end
	end

	def download
		info "Downloading #@asset_key from #@download_url"
		FileUtils.mkdir_p 'download'
		File.open @download_path, 'wb' do |file|
			file.write Net::HTTP.get URI @download_url
		end
	end

	def unzip
		Zip::File.open @download_path do |zip_file|
			zip_file.each do |entry|
				next unless entry.name == @unzip_file
				info "Unzipping #@unzip_file to #@unzip_path"
				FileUtils.rm @unzip_path if File.exist? @unzip_path
				entry.extract @unzip_path
			end
		end
	end

	def download_and_unzip_if_needed
		if downloaded_md5 != @download_md5
			download
			unzip
			return
		end

		info "#@asset_key already exists"
		if File.exist? @unzip_path
			info "#@unzip_file already exists"
		else
			unzip
		end
	end

	def init_db
		info "Loading database from #@unzip_path"
		@db = SQLite3::Database.new @unzip_path, readonly: true, results_as_hash: true
	end

	def init_secrets
		@secrets = Set[]
		@db.execute 'SELECT music_id, param1 FROM unknown' do |row|
			@secrets.add row['music_id']
		end
		@db.execute 'SELECT music_id FROM special' do |row|
			row['music_id'].split(?;).each { @secrets.add _1.to_i }
		end
		@db.execute <<~SQL do |row|
			SELECT id FROM music m WHERE EXISTS (
				SELECT id FROM note n WHERE n.id IN (
					m.note_id_1, m.note_id_2, m.note_id_3, m.note_id_4, m.note_id_5
				) AND EXISTS (
					SELECT 1 FROM unlock WHERE note_id = n.id AND music_param1 IN (SELECT id FROM music)
				) AND NOT EXISTS (
					SELECT 1 FROM unlock WHERE note_id = n.id AND music_param1 == m.id
				)
			)
		SQL
			@secrets.add row['id']
		end
	end

	def init_has_chaos
		@has_chaos = {}
		@has_non_chaos = {}
		@db.execute <<~SQL do |row|
			SELECT m1.id AS id1, m2.id AS id2 FROM music m1 JOIN music m2 ON m1.hash == m2.hash WHERE (
				m1.id != m2.id AND m1.chaos == 0 AND m2.chaos == 1
			)
		SQL
			@has_chaos[row['id1']] = row['id2']
			@has_non_chaos[row['id2']] = row['id1']
		end
	end

	def init_unlocks
		@unlocks = Hash.new { |h, k| h[k] = [] }
		@db.execute 'SELECT * FROM unlock' do |row|
			row.transform_keys! &:to_sym

			music = case row[:music_range]
			when 1 then find_music row[:music_param1]
			when 2 then :any
			when 4 then find_course row[:music_param1]
			end
			range_type = %i[_ difficulty level][row[:note_range]]
			range = row[:note_param1]..row[:note_param2]
			requirement_type = %i[_ play rank state][row[:status_type]]
			requirement = case requirement_type
			when :rank then %w[_ D C B A S S+][row[:status_param1]]
			when :state then %w[_ Failed Clear HC FC AP][row[:status_param1]]
			end
			count = row[:count]

			@unlocks[row[:note_id]].push({
				music:, range_type:, range:,
				requirement_type:, requirement:, count:
			})
		end
	end

	def each_music
		return enum_for :each_music unless block_given?
		count = 0
		@db.execute 'SELECT * FROM music' do |row|
			# break if count >= 100
			row.transform_keys! &:to_sym
			yield CharWasP::Music.new row
			count += 1
		end
	end

	def each_news
		return enum_for :each_news unless block_given?
		@db.execute 'SELECT * FROM notification ORDER BY date DESC' do |row|
			row.transform_keys! &:to_sym
			yield CharWasP::News.new row
		end
	end

	def find_music name
		if name.is_a? Integer
			@db.execute 'SELECT * FROM music WHERE id = ?', [name] do |row|
				row.transform_keys! &:to_sym
				return CharWasP::Music.new row
			end
			return
		end

		if name_without_chaos = name[/(.+) CHAOS/, 1]
			name = name_without_chaos
			chaos = 1
		else
			chaos = 0
		end
		@db.execute 'SELECT * FROM music WHERE name = ? AND chaos = ?', [name, chaos] do |row|
			row.transform_keys! &:to_sym
			return CharWasP::Music.new row
		end
		nil
	end

	def each_course
		return enum_for :each_course unless block_given?
		@db.execute 'SELECT * FROM course' do |row|
			row.transform_keys! &:to_sym
			yield CharWasP::Course.new row
		end
	end

	def find_course id
		@db.execute 'SELECT * FROM course WHERE id = ?', [id] do |row|
			row.transform_keys! &:to_sym
			return CharWasP::Course.new row
		end
		nil
	end

	def find_chart id
		@db.execute 'SELECT * FROM music WHERE ? IN (note_id_1, note_id_2, note_id_3, note_id_4, note_id_5)', [id] do |row|
			row.transform_keys! &:to_sym
			music = CharWasP::Music.new row
			return music.charts.find { _1.id == id }
		end
	end
end
