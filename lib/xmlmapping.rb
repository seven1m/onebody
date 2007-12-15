#
# Copyright (c) 2006 Martin Traverso
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'rexml/document'

module XMLMapping
	def self.included(mod)
		mod.extend(ClassMethods)

		mod.instance_variable_set("@raw_mappings", {})
		mod.instance_variable_set("@mappings", { :element => {}, :attribute => {}, :text => {}, :namespace => nil})
	end


	def initialize(input)
		root = parse(input)

		mappings = self.class.mappings
		raw_mappings = self.class.raw_mappings

		# initialize :many attributes
		raw_mappings.values.select { |mapping| mapping[:cardinality] == :many }.each { |m|
			instance_variable_set("@#{m[:attribute]}", [])
		}
		
		# initialize defaults
		raw_mappings.values.select { |mapping| mapping.has_key? :default }.each { |m|
			instance_variable_set("@#{m[:attribute]}", m[:default])
		}

		root.each_element { |e| 
			process(e, mappings[:element])
		}

		root.attributes.each_attribute { |a|
			process(a, mappings[:attribute])
		}

		mappings[:text].values.each { |mapping|
			name = mapping[:attribute]
			value = extract_value(root, mapping)
			instance_variable_set("@#{name}", value)
		}

	end


	private
	def process(e, mappings)
		mapping = find_mapping(mappings, e.namespace, e.name)

		if !mapping.nil?
			value = extract_value(e, mapping)

			attribute = mapping[:attribute]
			previous = instance_variable_get("@#{attribute}")
			case mapping[:cardinality]
				when :one 
					instance_variable_set("@#{attribute}", value)
				when :many 
					previous << value
			end		
		end
	end

	def find_mapping(mappings, namespace, name)
		mappings.values_at([namespace, name], [namespace, :any], [:any, :any] ).compact.first
	end

	def extract_value(node, mapping)
		if mapping.has_key? :type
			type = mapping[:type]
			if type == :raw
				value = node
			else
				value = mapping[:type].new(node)	
			end
		elsif node.node_type == :element
			value = node.texts.map { |t| t.value }.to_s
		elsif node.node_type == :attribute 
			value = node.value
		else
			raise "Unexpected node: #{node.inspect}"
		end

		if mapping.has_key? :transform
			value = mapping[:transform].call(value)
		end

		value
	end

	def parse(input)
		if input.respond_to? :to_str
			root = REXML::Document.new(input).root
		elsif input.respond_to?(:node_type) && input.node_type == :document
			root = input.root
		elsif input.respond_to?(:node_type) && input.node_type == :element
			root = input
		else 
			raise "Invalid input: #{input}"
		end

		root
	end

	module ClassMethods
		def raw_mappings
			@raw_mappings || superclass.raw_mappings 
		end

		def mappings
			@mappings || superclass.mappings 
		end

		def namespace(namespace)
			initialize_vars
			@mappings[:namespace] = namespace	
		end

		def has_one(attribute, options = {})
			options[:cardinality] = :one
			add(attribute, :element, options)
		end

		def has_many(attribute, options = {})
			options[:cardinality] = :many
			add(attribute, :element, options)
		end

		def has_attribute(attribute, options = {})
			add(attribute, :attribute, options)
		end	

		def text(attribute, options = {})
			options[:namespace] = :any
			add(attribute, :text, options)
		end

		def ensure(message, &block)
		end

		private 
		def add(attribute, xml_type, mapping)
			attr attribute
			
			initialize_vars

			mapping[:namespace] ||= mappings[:namespace]
			mapping[:cardinality] ||= :one
			mapping[:name] ||= attribute.to_s
			mapping[:attribute] = attribute

			qualified_name = [mapping[:namespace], mapping[:name]]
			mappings = @mappings[xml_type][qualified_name] = mapping

			@raw_mappings[attribute] = mapping
		end

		def initialize_vars
			@mappings ||= deep_clone(superclass.mappings)
			@raw_mappings ||= deep_clone(superclass.raw_mappings)
		end

		def deep_clone(obj)
			case obj
				when Hash	
					obj.entries.inject({}) { |hash, entry|
						hash[entry[0]] = deep_clone(entry[1])
						hash
					}
				when Array
					obj.map { |v| deep_clone[v] }
				else
					obj
			end
		end
	end
end
