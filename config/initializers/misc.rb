SUPER_ADMIN_CHECK = Proc.new do |person|
  Setting.get(:access, :super_admins).include? person.email
end

PEOPLE_ATTRIBUTES_SHOWABLE_ON_HOMEPAGE = %w(website service_name service_description service_phone service_email service_website activities interests music tv_shows movies books quotes about testimony )

SQLITE = Setting.connection.class.name =~ /sqlite/i rescue false