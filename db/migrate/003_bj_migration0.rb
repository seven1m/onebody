          class BjMigration0 < ActiveRecord::Migration
            def self.up
              Bj::Table.each{|table| table.up}
            end
            def self.down
              Bj::Table.reverse_each{|table| table.down}
            end
          end
