class Friendship < ApplicationRecord
  belongs_to :person
  belongs_to :friend, class_name: 'Person', foreign_key: 'friend_id'
  belongs_to :site

  scope_by_site_id

  validates :person, presence: true
  validates :friend, presence: true, uniqueness: { scope: %i(site_id person_id) }

  attr_accessor :skip_mirror

  before_create :mirror_friendship
  def mirror_friendship
    return if skip_mirror
    mirror = Friendship.new(person_id: friend_id)
    mirror.friend_id = person_id
    mirror.skip_mirror = true
    mirror.save!
  end

  def destroy
    Friendship.where(
      '(friend_id = ? and person_id = ?) or (friend_id = ? and person_id = ?)',
      person.id,
      friend.id,
      friend.id,
      person.id
    ).delete_all
  end
end
