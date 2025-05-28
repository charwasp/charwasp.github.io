module CharWasP::LiquidFilters
	def liquify input
		Liquid::Template.parse(Liquid::Utils.to_s(input), environment: @context.environment).render @context
	end
end

Liquid::Environment.default.register_filter CharWasP::LiquidFilters

module CharWasP::LiquidTags
	class Include < Liquid::Tag
		@template_cache = {}
		singleton_class.attr_reader :template_cache

		def initialize tag_name, path, tokens
			super
			@template = Include.template_cache[path] ||= Liquid::Template.parse File.read File.join 'template/include', path.strip + '.liquid'
		end

		def render context
			@template.render! context
		end

		def self.tag_name
			'include'
		end
	end

	constants.each do |name|
		klass = const_get name
		next unless klass.is_a? Class
		next unless klass.ancestors.include? Liquid::Tag
		Liquid::Environment.default.register_tag klass.tag_name, klass
	end
end
