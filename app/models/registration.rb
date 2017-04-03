class Registration < ActiveRecord::Base
  scope_by_site_id
  belongs_to :event
  belongs_to :person
  has_many :registrants
  has_many :people, through: :registrants
  has_many :extras, as: :object, class_name: 'RegistrationExtra'

  validates :event, :person, presence: true

  enum status: {
    pending: 0,
    complete: 1,
    canceled: 2
  }

  after_create :add_required_registrant_types

  def add_required_registrant_types
    event.registrant_types.required.each do |registrant_type|
      registrant = registrants.new(
        registrant_type: registrant_type
      )
      if registrant_type.default_to_user
        registrant.first_name = person.first_name
        registrant.last_name = person.last_name
      end
      registrant.save!
    end
    if registrants.none?
      registrants.create!(
        registrant_type: registrant_types.first
      )
    end
  end

  def to_react
    {
      id: id,
      status: status
    }
  end
end
