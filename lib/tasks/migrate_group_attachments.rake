namespace :onebody do
  desc 'Move files/attachments on Groups to new Documents system'
  task migrate_group_attachments: :environment do
    Site.each do |site|
      puts site.name
      parent_folder = DocumentFolder.find_or_create_by!(name: 'Group Folders')
      Group.find_each do |group|
        puts "  #{group.name}"
        next if group.attachments.empty?
        name = "Files for #{group.name}"
        folder = group.document_folders.find_or_create_by!(name: name, folder: parent_folder)
        group.attachments.each do |attachment|
          puts "    #{attachment.file_file_name}"
          folder.documents.create!(
            name: attachment.file_file_name,
            file: attachment.file
          )
        end
      end
    end
  end
end
