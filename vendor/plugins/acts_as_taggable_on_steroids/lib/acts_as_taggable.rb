module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    module Taggable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_taggable
          has_many :taggings, :as => :taggable, :dependent => :destroy, :include => :tag
          has_many :tags, :through => :taggings
          
          before_save :save_cached_tag_list
          after_save :save_tags
          
          include ActiveRecord::Acts::Taggable::InstanceMethods
          extend ActiveRecord::Acts::Taggable::SingletonMethods
          
          alias_method_chain :reload, :tag_list
        end
        
        def cached_tag_list_column_name
          "cached_tag_list"
        end
        
        def set_cached_tag_list_column_name(value = nil, &block)
          define_attr_method :cached_tag_list_column_name, value, &block
        end
      end
      
      module SingletonMethods
        # Pass either a tag string, or an array of strings or tags
        # 
        # Options:
        #   :exclude - Find models that are not tagged with the given tags
        #   :match_all - Find models that match all of the given tags, not just one
        #   :conditions - A piece of SQL conditions to add to the query
        def find_tagged_with(*args)
          options = find_options_for_find_tagged_with(*args)
          options.blank? ? [] : find(:all, options)
        end

        # will_paginate's method_missing function wants to hit
        # find_all_tagged_with if you call paginate_tagged_with, which is
        # obviously suboptimal
        def find_all_tagged_with(*args)
          find_tagged_with(*args)
        end
        
        def find_options_for_find_tagged_with(tags, options = {})
          tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)
          options = options.dup
          
          return {} if tags.empty?
          
          conditions = []
          conditions << sanitize_sql(options.delete(:conditions)) if options[:conditions]
          
          taggings_alias, tags_alias = "#{table_name}_taggings", "#{table_name}_tags"
          
          if options.delete(:exclude)
            conditions << <<-END
              #{table_name}.id NOT IN
                (SELECT #{Tagging.table_name}.taggable_id FROM #{Tagging.table_name}
                 INNER JOIN #{Tag.table_name} ON #{Tagging.table_name}.tag_id = #{Tag.table_name}.id
                 WHERE #{tags_condition(tags)} AND #{Tagging.table_name}.taggable_type = #{quote_value(base_class.name)})
            END
          else
            if options.delete(:match_all)
              conditions << <<-END
                (SELECT COUNT(*) FROM #{Tagging.table_name}
                 INNER JOIN #{Tag.table_name} ON #{Tagging.table_name}.tag_id = #{Tag.table_name}.id
                 WHERE #{Tagging.table_name}.taggable_type = #{quote_value(base_class.name)} AND
                 taggable_id = #{table_name}.id AND
                 #{tags_condition(tags)}) = #{tags.size}
              END
            else
              conditions << tags_condition(tags, tags_alias)
            end
          end
          
          { :select => "DISTINCT #{table_name}.*",
            :joins => "INNER JOIN #{Tagging.table_name} #{taggings_alias} ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key} AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)} " +
                      "INNER JOIN #{Tag.table_name} #{tags_alias} ON #{tags_alias}.id = #{taggings_alias}.tag_id",
            :conditions => conditions.join(" AND ")
          }.reverse_merge!(options)
        end
        
        # Calculate the tag counts for all tags.
        # 
        # Options:
        #  :start_at - Restrict the tags to those created after a certain time
        #  :end_at - Restrict the tags to those created before a certain time
        #  :conditions - A piece of SQL conditions to add to the query
        #  :limit - The maximum number of tags to return
        #  :order - A piece of SQL to order by. Eg 'tags.count desc' or 'taggings.created_at desc'
        #  :at_least - Exclude tags with a frequency less than the given value
        #  :at_most - Exclude tags with a frequency greater than the given value
        def tag_counts(options = {})
          Tag.find(:all, find_options_for_tag_counts(options))
        end

        # Find how many objects are tagged with a certain tag.
        def count_by_tag(tag_name)
          counts = tag_counts(:conditions => "tags.name = #{quote_value(tag_name)}")
          counts[0].respond_to?(:count) ? counts[0].count : 0
        end
        
        def find_options_for_tag_counts(options = {})
          options.assert_valid_keys :start_at, :end_at, :conditions, :at_least, :at_most, :order, :limit
          options = options.dup
          
          scope = scope(:find)
          start_at = sanitize_sql(["#{Tagging.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
          end_at = sanitize_sql(["#{Tagging.table_name}.created_at <= ?", options.delete(:end_at)]) if options[:end_at]
          
          conditions = [
            "#{Tagging.table_name}.taggable_type = #{quote_value(base_class.name)}",
            sanitize_sql(options.delete(:conditions)),
            scope && scope[:conditions],
            start_at,
            end_at
          ]
          
          conditions << type_condition unless descends_from_active_record? 
          conditions.compact!
          conditions = conditions.join(' AND ')
          
          joins = ["INNER JOIN #{Tagging.table_name} ON #{Tag.table_name}.id = #{Tagging.table_name}.tag_id"]
          joins << "INNER JOIN #{table_name} ON #{table_name}.#{primary_key} = #{Tagging.table_name}.taggable_id"
          joins << scope[:joins] if scope && scope[:joins]
          
          at_least  = sanitize_sql(['COUNT(*) >= ?', options.delete(:at_least)]) if options[:at_least]
          at_most   = sanitize_sql(['COUNT(*) <= ?', options.delete(:at_most)]) if options[:at_most]
          having    = [at_least, at_most].compact.join(' AND ')
          group_by  = "#{Tag.table_name}.id, #{Tag.table_name}.name HAVING COUNT(*) > 0"
          group_by << " AND #{having}" unless having.blank?
          
          { :select     => "#{Tag.table_name}.id, #{Tag.table_name}.name, COUNT(*) AS count", 
            :joins      => joins.join(" "),
            :conditions => conditions,
            :group      => group_by
          }.reverse_merge!(options)
        end
        
        def caching_tag_list?
          column_names.include?(cached_tag_list_column_name)
        end
        
       private
        def tags_condition(tags, table_name = Tag.table_name)
          condition = tags.map { |t| sanitize_sql(["#{table_name}.name LIKE ?", t]) }.join(" OR ")
          "(" + condition + ")"
        end
      end
      
      module InstanceMethods
        def tag_list
          return @tag_list if @tag_list
          
          if self.class.caching_tag_list? and !(cached_value = send(self.class.cached_tag_list_column_name)).nil?
            @tag_list = TagList.from(cached_value)
          else
            @tag_list = TagList.new(*tags.map(&:name))
          end
        end
        
        def tag_list=(value)
          @tag_list = TagList.from(value)
        end
        
        def save_cached_tag_list
          if self.class.caching_tag_list?
            self[self.class.cached_tag_list_column_name] = tag_list.to_s
          end
        end
        
        def save_tags
          return unless @tag_list
          
          new_tag_names = @tag_list - tags.map(&:name)
          old_tags = tags.reject { |tag| @tag_list.include?(tag.name) }
          
          self.class.transaction do
            if old_tags.any?
              taggings.find(:all, :conditions => ["tag_id IN (?)", old_tags.map(&:id)]).each(&:destroy)
              taggings.reset
            end
            
            new_tag_names.each do |new_tag_name|
              tags << Tag.find_or_create_with_like_by_name(new_tag_name)
            end
          end
          
          true
        end
        
        # Calculate the tag counts for the tags used by this model.
        #
        # The possible options are the same as the tag_counts class method, excluding :conditions.
        def tag_counts(options = {})
          self.class.tag_counts({ :conditions => self.class.send(:tags_condition, tag_list) }.reverse_merge!(options))
        end
        
        def reload_with_tag_list(*args) #:nodoc:
          @tag_list = nil
          reload_without_tag_list(*args)
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecord::Acts::Taggable)
