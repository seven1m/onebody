class RegistrantRelease < ActiveRecord::Base
  belongs_to :event
  belongs_to :registrant_type

  validates :event, :registrant_type, :name, :description, presence: true

  def to_react
    {
      name: name,
      description: description,
      required: required
    }
  end
end
