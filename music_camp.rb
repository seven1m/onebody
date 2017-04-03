# use 4

Event.destroy_all

event = Event.create!(
  name: 'Music Camp 2017',
  description: <<-END,
**20th Celebration!!** Music Camp was started way back in 1997 and has been encouraging kids to love Jesus in a musical way.

**Love. Music. Jesus.** This is the mark of Music Camp.  Our theme this year is based on [Mark 12:30-31](https://www.bible.com/bible/1/MRK.12.30-31). Come experience the _Mark of a Minion_!

## July 10 to 14, 2017 from 9:00 a.m. to 12:00 p.m.

To conclude each music camp week, there will be a final performance Friday at 6:30 p.m. in the BA Campus Worship Center. Invite your family and friends to come see what your kids learned.

* Preschool Area: 4-5 year old classes are limited to 40 participants per age.
* Elementary Area: Kindergarten - Third grade classes are limited to 100 participants. (Grade is based on 2016/2017 School Year)
* Elementary Area: Fourth - Fifth grade classes are limited to 25 participants. (Grade is based on 2016/2017 School Year)

Contact Information: (918) 928-7228 or music.camp.volunteer@cedarridgecc.com
  END
  visibility: :anyone_with_link,
)

event.registrant_types.create!(
  name: 'Parent/Guardian',
  required: true,
  base_cost: 0,
  ordering: 1,
  require_contact_phone: true,
  require_contact_address: true,
  default_to_user: true
)

participant = event.registrant_types.create!(
  name: 'Participant',
  base_cost: 35,
  ordering: 2
)

full_time_volunteer = event.registrant_types.create!(
  name: 'Volunteer 20 Hours or More',
  base_cost: 0,
  ordering: 3
)

part_time_volunteer = event.registrant_types.create!(
  name: 'Volunteer Less Than 20 Hours',
  base_cost: 0,
  ordering: 3
)

event.discount_rules.create!(
  kind: 'registrant',
  name: 'Full Time Volunteer',
  if_registrant_type: full_time_volunteer,
  then_registrant_type: participant,
  discount_fixed: 25
)

event.discount_rules.create!(
  kind: 'registrant',
  name: 'Part Time Volunteer',
  if_registrant_type: part_time_volunteer,
  then_registrant_type: participant,
  discount_fixed: 10
)

event.extras.create!(
  kind: 'registration',
  name: 'Pre-order a DVD of the July 14 Performance',
  cost: 5,
  available: 100,
  ordering: 1
)

event.extras.create!(
  kind: 'registration',
  name: 'Donation: helping Music Camp general needs',
  cost: 15,
  ordering: 2
)

event.extras.create!(
  kind: 'registration',
  name: "Donation: Sponsor someone else's child",
  cost: 35,
  ordering: 3
)

event.extras.create!(
  kind: 'registrant',
  name: 'Pre-pay for Breakfast for the week',
  cost: 5,
  ordering: 1,
  limit_per: 1
)

event.registrant_releases.create!(
  name: 'Photo Release',
  description: 'bla bla bla',
  registrant_type: participant
)

event.registrant_releases.create!(
  name: 'Contact Release',
  description: 'bla bla bla',
  registrant_type: participant
)

participant.custom_fields.create!(
  name: 'T-shirt Size',
  format: 'select',
  options: ['Kids XS (2/4)', 'Kids S (6/8)', 'Kids M (10/12)', 'Kids L (14/16)', 'Kids XL (18/20 or Adult XS', 'Adult S', 'Adult M', 'Adult L', 'Adult XL', 'Adult 2XL', 'Adult 3XL'],
  kind: 'registration',
  required: true
)

full_time_volunteer.custom_fields.create!(
  name: 'T-shirt Size',
  format: 'select',
  options: ['Kids XS (2/4)', 'Kids S (6/8)', 'Kids M (10/12)', 'Kids L (14/16)', 'Kids XL (18/20 or Adult XS', 'Adult S', 'Adult M', 'Adult L', 'Adult XL', 'Adult 2XL', 'Adult 3XL'],
  kind: 'registration',
  required: true
)

part_time_volunteer.custom_fields.create!(
  name: 'T-shirt Size',
  format: 'select',
  options: ['Kids XS (2/4)', 'Kids S (6/8)', 'Kids M (10/12)', 'Kids L (14/16)', 'Kids XL (18/20 or Adult XS', 'Adult S', 'Adult M', 'Adult L', 'Adult XL', 'Adult 2XL', 'Adult 3XL'],
  kind: 'registration',
  required: true
)

p event.id
