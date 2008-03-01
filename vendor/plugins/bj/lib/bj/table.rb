class Bj
#
# table base class
#
  class Table < ActiveRecord::Base
    module ClassMethods
      attribute("list"){ Array.new }
      attribute("migration"){}

      def migration_code classname = "BjMigration"
        <<-code
          class #{ classname } < ActiveRecord::Migration
            def self.up
              Bj::Table.each{|table| table.up}
            end
            def self.down
              Bj::Table.reverse_each{|table| table.down}
            end
          end
        code
      end

      def up
        migration_class.up
      end

      def down
        migration_class.down
      end

      def migration_class
        table = self
        @migration_class ||=
          Class.new(ActiveRecord::Migration) do
            sc =
              class << self
                self
              end
            sc.module_eval{ attribute :table => table }
            sc.module_eval &table.migration
          end
      end

      def content_column_names
        @content_column_names = content_columns.map{|column| column.name}
      end

      def create_hash_for options
        options.to_options!
        hash = {}
        content_column_names.each do |key|
          key = key.to_s.to_sym
          hash[key] = options[key]
        end
        hash
      end

      def each *a, &b
        list.each *a, &b
      end

      def reverse_each *a, &b
        list.reverse.each *a, &b
      end
    end
    send :extend, ClassMethods

    module InstanceMethods
      def to_hash
        oh = OrderedHash.new
        self.class.content_column_names.each{|c| oh[c] = self[c]}
        oh
      end
    end
    send :include, InstanceMethods

    module RecursivelyInherited
      def inherited other
        super
      ensure
        (Table.list << other).uniq!
        basename = other.name.split(%r/::/).last.underscore
        Table.singleton_class{ attribute basename => other }
        other.send :extend, RecursivelyInherited
      end
    end
    send :extend, RecursivelyInherited

#
# table classes
#
    class Job < Table
      set_table_name "bj_job"
      set_primary_key "#{ table_name }_id"

      migration { 
        define_method :up do
          create_table table.table_name, :primary_key => table.primary_key, :force => true do |t|
            t.column "command"        , :text

            t.column "state"          , :text
            t.column "priority"       , :integer
            t.column "tag"            , :text
            t.column "is_restartable" , :integer

            t.column "submitter"      , :text
            t.column "runner"         , :text
            t.column "pid"            , :integer

            t.column "submitted_at"   , :datetime
            t.column "started_at"     , :datetime
            t.column "finished_at"    , :datetime

            t.column "env"            , :text
            t.column "stdin"          , :text
            t.column "stdout"         , :text
            t.column "stderr"         , :text
            t.column "exit_status"    , :integer
          end
        end

        define_method :down do
          drop_table table.table_name 
        end
      }

      module ClassMethods
        def submit jobs, options = {}, &block
          jobs = Joblist.for jobs, options
          returned = []
          transaction do
            jobs.each do |job|
              job = create_hash_for(job.reverse_merge(submit_defaults))
              job = create! job 
              returned << (block ? block.call(job) : job)
            end
          end
          returned
        end

        def submit_defaults
          {
            :state => "pending",
            :priority => 0,
            :tag => "",
            :is_restartable => true,
            :submitter => Bj.hostname,
            :submitted_at => Time.now, 
          }
        end
      end
      send :extend, ClassMethods

      module InstanceMethods
        def title
          "job[#{ id }](#{ command })"
        end
        def finished
          reload
          exit_status
        end
        alias_method "finished?", "finished"
      end
      send :include, InstanceMethods
    end

    class JobArchive < Job
      set_table_name "bj_job_archive"
      set_primary_key "#{ table_name }_id"

      migration {
        define_method(:up) do
          create_table table.table_name, :primary_key => table.primary_key, :force => true do |t|
            t.column "command"        , :text

            t.column "state"          , :text
            t.column "priority"       , :integer
            t.column "tag"            , :text
            t.column "is_restartable" , :integer

            t.column "submitter"      , :text
            t.column "runner"         , :text
            t.column "pid"            , :integer

            t.column "submitted_at"   , :datetime
            t.column "started_at"     , :datetime
            t.column "finished_at"    , :datetime
            t.column "archived_at"    , :datetime

            t.column "env"            , :text
            t.column "stdin"          , :text
            t.column "stdout"         , :text
            t.column "stderr"         , :text
            t.column "exit_status"    , :integer
          end
        end

        define_method(:down) do
          drop_table table.table_name
        end
      }
    end

  # TODO - initialize with a set of global defaults and fallback to those on perhaps '* * key'
    class Config < Table
      set_table_name "bj_config"
      set_primary_key "#{ table_name }_id"

      migration {
        define_method(:up) do
          create_table table.table_name, :primary_key => table.primary_key, :force => true do |t|
            t.column "hostname"      , :text
            t.column "key"           , :text
            t.column "value"         , :text
            t.column "cast"          , :text
          end

          begin
            add_index table.table_name, %w[ hostname key ], :unique => true
          rescue Exception
            STDERR.puts "WARNING: your database does not support unique indexes on text fields!?"
          end
        end

        define_method(:down) do
          begin
            remove_index table.table_name, :column => %w[ hostname key ] 
          rescue Exception
          end
          drop_table table.table_name
        end
      }

      module ClassMethods
        def [] key
          get key
        end

        def get key, options = {}
          transaction do
            options.to_options!
            hostname = options[:hostname] || Bj.hostname
            record = find :first, :conditions => conditions(:key => key, :hostname => hostname) 
            record ? record.value : default_for(key) 
          end
        end

        def conditions options = {}
          options.to_options!
          options.reverse_merge!(
            :hostname => Bj.hostname
          )
          options
        end

        def default_for key
          record = find :first, :conditions => conditions(:key => key, :hostname => '*')
          record ? record.value : nil 
        end

        def []= key, value
          set key, value
        end

        def set key, value, options = {}
          transaction do
            options.to_options!
            hostname = options[:hostname] || Bj.hostname
            record = find :first, :conditions => conditions(:key => key, :hostname => hostname), :lock => true
            cast = options[:cast] || cast_for(value)
            key = key.to_s
            value = value.to_s
            if record
              record["value"] = value
              record["cast"] = cast
              record.save!
            else
              create! :hostname => hostname, :key => key, :value => value, :cast => cast
            end
            value
          end
        end

        def delete key
          transaction do
            record = find :first, :conditions => conditions(:key => key), :lock => true
            if record
              record.destroy
              record
            else
              nil
            end
          end
        end

        def has_key? key
          record = find :first, :conditions => conditions(:key => key)
          record ? record : false
        end
        alias_method "has_key", "has_key?"

        def keys
          find(:all, :conditions => conditions).map(&:key)
        end

        def values
          find(:all, :conditions => conditions).map(&:value)
        end

        def for options = {}
          oh = OrderedHash.new
          find(:all, :conditions => conditions(options)).each do |record|
            oh[record.key] = record.value
          end
          oh
        end

        def cast_for value
          case value
            when TrueClass, FalseClass
              'to_bool'
            when NilClass
              'to_nil'
            when Fixnum, Bignum
              'to_i'
            when Float
              'to_f'
            when Time
              'to_time'
            when Symbol
              'to_sym'
            else
              case value.to_s
                when %r/^\d+$/
                  'to_i'
                when %r/^\d+\.\d+$/
                  'to_f'
                when %r/^nil$|^$/
                  'to_nil'
                when %r/^true|false$/
                  'to_bool'
                else
                  'to_s'
              end
          end
        end

        def casts
          @casts ||= {
            'to_bool' => lambda do |value|
              value.to_s =~ %r/^true$/i ? true : false
            end,
            'to_i' => lambda do |value|
              Integer value.to_s.gsub(%r/^(-)?0*/,'\1')
            end,
            'to_f' => lambda do |value|
              Float value.to_s.gsub(%r/^0*/,'')
            end,
            'to_time' => lambda do |value|
              Time.parse(value.to_s)
            end,
            'to_sym' => lambda do |value|
              value.to_s.to_sym
            end,
            'to_nil' => lambda do |value|
              value.to_s =~ %r/^nil$|^$/i ? nil : value.to_s 
            end,
            'to_s' => lambda do |value|
              value.to_s
            end,
          }
        end
      end
      send :extend, ClassMethods

      module InstanceMethods
        def value 
          self.class.casts[cast][self["value"]]
        end
      end
      send :include, InstanceMethods
    end
  end
end
