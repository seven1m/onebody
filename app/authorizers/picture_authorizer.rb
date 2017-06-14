class PictureAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    resource.album.readable_by?(user)
  end

  def creatable_by?(user)
    resource.person == user ||
      (resource.album && resource.album.creatable_by?(user))
  end

  def updatable_by?(user)
    resource.person == user ||
      resource.album.updatable_by?(user)
  end

  alias deletable_by? updatable_by?
  alias rotatable_by? updatable_by?

  def self.readable_by(_user, _scope = Picture.all)
  end
end
