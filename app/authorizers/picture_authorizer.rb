class PictureAuthorizer < ApplicationAuthorizer

  def readable_by?(user)
    resource.album.readable_by?(user)
  end

  def creatable_by?(user)
    resource.person == user or
    resource.album.creatable_by?(user)
  end

  def updatable_by?(user)
    resource.person == user or
    resource.album.updatable_by?(user)
  end

  alias_method :deletable_by?, :updatable_by?
  alias_method :rotatable_by?, :updatable_by?

  def self.readable_by(user, scope = Picture.all)
  end

end
