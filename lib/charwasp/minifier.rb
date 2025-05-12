module CharWasP::Minifier
	module_function

	def min_js js
		min_html("<script>#{js}</script>")['<script>'.length...-'</script>'.length]
	end

	def min_css css
		min_html("<style>#{css}</style>")['<style>'.length...-'</style>'.length]
	end

	def min_html html
		minify_html html, minify_css: true, minify_js: true
	end

	def min_svg svg
		svg # TODO
	end
end
