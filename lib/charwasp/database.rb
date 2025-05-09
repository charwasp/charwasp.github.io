class CharWasP::Database
	include CharWasP::Logger

	attr_reader :secrets

	def initialize
		init_params
		download_and_unzip_if_needed
		init_db
		init_secrets
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
		info 'Loading secrets'
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

	def get_row table, id
		row = @db.get_first_row "SELECT * FROM #{table} WHERE id = ?", id
		row.transform_keys! &:to_sym
		row
	end

	def music id
		row = get_row 'music', id
		CharWasP::Music.new row if row
	end

	def each_music
		return enum_for :each_music unless block_given?
		@db.execute 'SELECT * FROM music' do |row|
			row.transform_keys! &:to_sym
			yield CharWasP::Music.new row
		end
	end
end
