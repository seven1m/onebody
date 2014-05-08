class Person
  module Friend
    def request_friendship_with(person)
      if person.friendship_waiting_on?(self)
        # already requested by other person
        self.friendships.create! friend: person
        self.friendship_requests.where(from_id: person.id).first.destroy
        I18n.t('friends.added_as_friend', name: person.name)
      elsif self.can_request_friendship_with?(person)
        # clean up past rejections
        FriendshipRequest.delete_all ['person_id = ? and from_id = ? and rejected = ?', self.id, person.id, true]
        person.friendship_requests.create!(from: self)
        I18n.t('friends.request_sent', name: person.name)
      elsif self.friendship_waiting_on?(person)
        I18n.t('friends.already_pending', name: person.name)
      elsif self.friendship_rejected_by?(person)
        I18n.t('friends.cannot_request', name: person.name)
      else
        raise I18n.t('friends.unknown_state')
      end
    end

    def can_request_friendship_with?(person)
      Setting.get(:features, :friends) and person != self and person.family_id != self.family_id and !friend?(person) and full_access? and person.full_access? and person.valid_email? and person.friends_enabled and !friendship_rejected_by?(person) and !friendship_waiting_on?(person)
    end

    def friendship_rejected_by?(person)
      person.friendship_requests.where(from_id: id, rejected: true).count > 0
    end

    def friendship_waiting_on?(person)
      person.friendship_requests.where(from_id: id, rejected: false).count > 0
    end

    def friend?(person)
      friends.where('friendships.friend_id' => person.id).count > 0
    end
  end
end
