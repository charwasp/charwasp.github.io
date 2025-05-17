require 'json'
require 'net/http'
require 'digest'
require 'fileutils'

require 'zip'
require 'sqlite3'
require 'liquid'
require 'minify_html'
require 'base64'

begin
	require 'tqdm'
rescue LoadError
	Enumerable.define_method(:with_progress) { |*args, **opts| self }
end

module CharWasP
end

require 'charwasp/logger'
require 'charwasp/minifier'
require 'charwasp/database'
require 'charwasp/music'
require 'charwasp/chart'
require 'charwasp/news'
require 'charwasp/course'
require 'charwasp/special'
require 'charwasp/generator'

class << CharWasP
	include CharWasP::Logger
	attr_reader :package_url, :assets, :db, :site_url

	def manifest
		info 'Downloading manifest'
		response = Net::HTTP.get_response URI ENV['CHARWASP_MANIFEST_URL']
		JSON.parse response.body, symbolize_names: true
	end

	def fetch_upstream
		if ENV['CHARWASP_PACKAGE_URL'] && ENV['CHARWASP_MASTER_ZIP_SIG']
			@package_url = +ENV['CHARWASP_PACKAGE_URL']
			@assets = { 'master.zip' => { md5: ENV['CHARWASP_MASTER_ZIP_SIG'] } }
		else
			@package_url, @assets = manifest.values_at *%i[packageUrl assets]
			@package_url.sub! %r{^http://}, 'https://'
			@assets.transform_keys! &:to_s
		end
		@package_url.sub! %r{/$}, ''
		@package_url.freeze
		@assets.freeze
	end

	def init_db
		@db = CharWasP::Database.new
		@db.init
	end

	def run
		@site_url = ENV['CHARWASP_SITE_URL']
		fetch_upstream
		init_db
		CharWasP::Generator.new.generate
	end
end
