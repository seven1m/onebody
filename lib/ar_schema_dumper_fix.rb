module ActiveRecord
  class SchemaDumper
    private
      def table(table, stream)
        columns = @connection.columns(table)
        begin
          tbl = StringIO.new

          if @connection.respond_to?(:pk_and_sequence_for)
            pk, pk_seq = @connection.pk_and_sequence_for(table)
          end
          pk ||= 'id'

          tbl.print "  create_table #{table.inspect}"
          if columns.detect { |c| c.name == pk }
            if pk != 'id'
              tbl.print %Q(, :primary_key => "#{pk}")
            end
          else
            tbl.print ", :id => false"
          end
          tbl.print ", :force => true"
          tbl.puts " do |t|"

          column_specs = columns.map do |column|
            raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
            next if column.name == pk
            spec = {}
            spec[:name]    = column.name.inspect
# # # # # # # # # this is the only line I changed...
            spec[:type]    = column.sql_type =~ /bigint/ ? ':bigint' : column.type.inspect
            spec[:limit]   = column.limit.inspect if column.limit != @types[column.type][:limit] && column.type != :decimal
            spec[:precision] = column.precision.inspect if !column.precision.nil?
            spec[:scale] = column.scale.inspect if !column.scale.nil?
            spec[:null]    = 'false' if !column.null
            spec[:default] = default_string(column.default) if !column.default.nil?
            (spec.keys - [:name, :type]).each{ |k| spec[k].insert(0, "#{k.inspect} => ")}
            spec
          end.compact
          keys = [:name, :type, :limit, :precision, :scale, :default, :null] & column_specs.map{ |spec| spec.keys }.inject([]){ |a,b| a | b }
          lengths = keys.map{ |key| column_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }
          format_string = lengths.map{ |len| "%-#{len}s" }.join("")
          column_specs.each do |colspec|
            values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
            tbl.print "    t.column "
            tbl.print((format_string % values).gsub(/,\s*$/, ''))
            tbl.puts
          end

          tbl.puts "  end"
          tbl.puts
          
          indexes(table, tbl)

          tbl.rewind
          stream.print tbl.read
        rescue => e
          stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
          stream.puts "#   #{e.message}"
          stream.puts
        end
        
        stream
      end
  end
end