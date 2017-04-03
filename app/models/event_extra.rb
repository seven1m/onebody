class EventExtra < ActiveRecord::Base
  scope_by_site_id

  belongs_to :event

  validates :event, :name, :cost, presence: true
  validates :kind, inclusion: %w(registration registrant)

  def to_react
    {
      kind: kind,
      name: name,
      description: description,
      cost: cost,
      available: available,
      limit_per: limit_per
    }
  end
end
