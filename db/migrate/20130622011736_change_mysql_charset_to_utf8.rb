class ChangeMysqlCharsetToUtf8 < ActiveRecord::Migration
  def self.up
    db = Rails.configuration.database_configuration[Rails.env]['database']
    columns = ActiveRecord::Base.connection.select_rows("SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, CHARACTER_MAXIMUM_LENGTH  FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='#{db}';")
    columns.each do |table, column, type, limit|
      next unless type =~ /varchar|text/
      new_type = type.sub(/varchar/i, 'varbinary').sub(/text/i, 'blob')
      puts "converting #{table} #{column}..."
      # thanks to Mike Perham for this tip
      # http://www.mikeperham.com/2012/03/31/converting-a-mysql-database-from-latin1-to-utf8/
      ActiveRecord::Base.connection.execute("ALTER TABLE #{table} CHARACTER SET utf8 COLLATE utf8_unicode_ci, CHANGE #{column} #{column} #{new_type};")
      ActiveRecord::Base.connection.execute("ALTER TABLE #{table} CHANGE #{column} #{column} #{type} CHARACTER SET utf8 COLLATE utf8_unicode_ci;")
    end
    puts "done!"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
