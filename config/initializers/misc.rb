SUPER_ADMIN_CHECK = Proc.new do |person|
  SETTINGS['access']['super_admins'].include? person.email
end

PEOPLE_ATTRIBUTES_SHOWABLE_ON_HOMEPAGE = %w(website service_name service_description service_phone service_email service_website activities interests music tv_shows movies books quotes about testimony )

# SQLite support on OneBody is non-existent right now
SQLITE = false #Person.connection.class == ActiveRecord::ConnectionAdapters::SQLite3Adapter
SQL_LCASE = SQLITE ? 'LOWER' : 'LCASE'
