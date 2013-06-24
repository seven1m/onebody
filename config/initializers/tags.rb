# extend Tag model from acts_as_taggable_on_steroids
Tag.class_eval { include TagConcern }

TagList.delimiter = /\s+|,/
