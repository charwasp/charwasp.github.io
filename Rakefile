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

task default: :build
