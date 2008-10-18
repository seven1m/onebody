namespace :onebody do
  task :fix_unmirrored_friendships => :environment do
    Site.each do
      Friendship.all.each do |friendship|
        if !Friendship.find_by_person_id_and_friend_id(friendship.friend_id, friendship.person_id)
          puts "#{friendship.friend.name} => #{friendship.person.name} missing"
          f = Friendship.new(
            :person_id => friendship.friend_id,
            :friend_id => friendship.person_id
          )
          f.skip_mirror = true
          f.save!
        end
      end
    end
  end
end
