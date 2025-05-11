require 'json'
require 'net/http'
require 'digest'
require 'fileutils'

require 'logger'
require 'zip'
require 'sqlite3'
require 'liquid'
require 'minify_html'

module CharWasP
end

require 'charwasp/logger'
require 'charwasp/database'
require 'charwasp/music'
require 'charwasp/chart'
require 'charwasp/news'
require 'charwasp/course'
require 'charwasp/special'
require 'charwasp/generator'

class << CharWasP
	include CharWasP::Logger
	attr_reader :package_url, :assets, :db

	def manifest
		info 'Downloading manifest'
		response = Net::HTTP.get_response URI ENV['CHARWASP_MANIFEST_URL']
		JSON.parse response.body, symbolize_names: true
	end

	def run
		@package_url, @assets = manifest.values_at *%i[packageUrl assets]
		@package_url.sub! %r{^http://}, 'https://'
		@assets.transform_keys! &:to_s

		@db = CharWasP::Database.new
		@db.init

		CharWasP::Generator.new.generate
	end
end
