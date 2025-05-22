$:.push File.expand_path 'lib', __dir__

task :build do
	require 'charwasp'
	CharWasP.run
end

task :serve do
	require 'webrick'
	server = WEBrick::HTTPServer.new Port: 3134, DocumentRoot: 'dist', BindAddress: '0.0.0.0'
	trap(:INT) { server.shutdown }
	server.start
end

task :hash_data do
	require 'digest'
	require 'json'
	hashes = Dir.glob('data/*.json').each_with_object({}) { _2[_1] = Digest::MD5.file(_1).hexdigest }
	File.open(ENV['GITHUB_OUTPUT'], 'a') { _1.puts "data-hash=" + Digest::MD5.hexdigest(hashes.to_json) }
end

task default: :build
