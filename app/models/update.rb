class Update < ApplicationRecord
  belongs_to :person
  belongs_to :site

  scope_by_site_id

  scope :pending, -> { where(complete: false) }
  scope :complete, -> { where(complete: true) }

  serialize :data, Hash
  serialize :diff, Hash

  # convert ActionController::Parameters and HWIA to a Hash
  def data=(d)
    self[:data] = data_to_hash(d)
  end

  def child=(c)
    self[:data][:person]['child'] = c
  end

  # update_attributes!(apply: true) will call apply!
  attr_accessor :apply
  after_save { apply! if apply && !complete? }

  after_create :notify_admin

  def apply!
    return false if complete?
    transaction do
      record_diff
      person.update_attributes!(data[:person]) if data[:person]
      family.update_attributes!(data[:family]) if data[:family]
      update_attributes!(complete: true)
    end
  end

  def family
    person.try(:family)
  end

  def diff
    if complete?
      self[:diff].any? ? self[:diff] : data_as_diff
    else
      pending_changes
    end
  end

  # returns true if applying the update requires that the admin
  # specify if the person is a child, e.g. *removing* a birthday
  def require_child_designation?
    return false unless data[:person]
    person.attributes = data[:person] # temporarily set attrs
    person.valid?                     # force validation check
    person.errors[:child].any?.tap do # errors on :child?
      person.reload                   # reset attrs
    end
  end

  private

  def pending_changes
    HashWithIndifferentAccess.new(
      person: Comparator.new(person, data[:person]).changes,
      family: Comparator.new(family, data[:family]).changes
    )
  end

  def record_diff
    self.diff = pending_changes
  end

  # update data in a diff format
  # to support legacy records (before we started storing the diff)
  def data_as_diff
    HashWithIndifferentAccess.new(
      person: faux_diff_attributes(data[:person]),
      family: faux_diff_attributes(data[:family])
    )
  end

  # convert top level and second level to Hash class
  # ensure top level is symbol
  def data_to_hash(data)
    if data.is_a?(ActionController::Parameters)
      data.to_unsafe_h.symbolize_keys # 'unsafe' is ok here because we filter our own params
    else
      data.to_hash.symbolize_keys
    end
  end

  # build a fake diff with :unknown as the source
  def faux_diff_attributes(attrs)
    return {} unless attrs && attrs.any?
    attrs.each_with_object({}) do |(key, val), hash|
      hash[key] = [:unknown, val]
    end
  end

  def notify_admin
    return if Setting.get(:contact, :send_updates_to).blank?
    Notifier.profile_update(person).deliver_now
  end
end
