gem_dir = Gem::Specification.find_by_name("acts_as_taggable_on_steroids").gem_dir
require File.join(gem_dir, 'app/models/tag')

Tag.class_eval { include TagConcern }
