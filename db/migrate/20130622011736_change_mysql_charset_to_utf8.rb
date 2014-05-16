class ChangeMysqlCharsetToUtf8 < ActiveRecord::Migration
  def self.up
    db = Rails.configuration.database_configuration[Rails.env]['database']
    tables = ActiveRecord::Base.connection.select_rows("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='#{db}';")
    tables.each do |row|
      puts "converting #{row[0]} to utf8..."
      ActiveRecord::Base.connection.execute("ALTER TABLE #{row[0]} CONVERT TO CHARACTER SET utf8;")
    end
    puts "done!"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
