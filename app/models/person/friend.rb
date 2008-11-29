class Person
  module Friend
    def request_friendship_with(person)
      if person.friendship_waiting_on?(self)
        # already requested by other person
        self.friendships.create! :friend => person
        self.friendship_requests.find_by_from_id(person.id).destroy
        "#{person.name} has been added as a friend."
      elsif self.can_request_friendship_with?(person)
        # clean up past rejections
        FriendshipRequest.delete_all ['person_id = ? and from_id = ? and rejected = ?', self.id, person.id, true]
        person.friendship_requests.create!(:from => self)
        "A friend request has been sent to #{person.name}."
      elsif self.friendship_waiting_on?(person)
        "A friend request is already pending with #{person.name}."
      elsif self.friendship_rejected_by?(person)
        "You cannot request friendship with #{person.name}."
      else
        raise 'unknown state'
      end
    end

    def can_request_friendship_with?(person)
      person != self and !friend?(person) and full_access? and person.full_access? and person.valid_email? and person.friends_enabled and !friendship_rejected_by?(person) and !friendship_waiting_on?(person)
    end

    def friendship_rejected_by?(person)
      person.friendship_requests.count('*', :conditions => ['from_id = ? and rejected = ?', self.id, true]) > 0
    end

    def friendship_waiting_on?(person)
      person.friendship_requests.count('*', :conditions => ['from_id = ? and rejected = ?', self.id, false]) > 0
    end

    def friend?(person)
      friends.count('*', :conditions => ['friend_id = ?', person.id]) > 0
    end
  end
end