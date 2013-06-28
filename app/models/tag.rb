path = ActsAsTaggable::Engine.config.eager_load_paths.grep(/models/).first
require File.join(path, 'tag')

Tag.class_eval { include TagConcern }
