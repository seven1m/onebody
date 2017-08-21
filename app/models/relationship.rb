class Relationship < ApplicationRecord
  belongs_to :person
  belongs_to :related, foreign_key: 'related_id', class_name: 'Person'

  scope_by_site_id

  validates_presence_of :name
  validates_presence_of :other_name, if: proc { |r| r.name == 'other' }
  validates_presence_of :person
  validates_presence_of :related
  validates_uniqueness_of :name, scope: %i(site_id other_name person_id related_id)
  validates_uniqueness_of :other_name, scope: %i(site_id name person_id related_id)
  validates_each :name do |record, attribute, value|
    unless I18n.t('relationships.names').keys.map(&:to_s).include?(value) || value == 'other'
      record.errors.add attribute, :inclusion
    end
  end

  def name_or_other
    name == 'other' ? other_name : I18n.t(name, scope: 'relationships.names')
  end

  def reciprocate
    if can_auto_reciprocate?
      Relationship.create(person: related, related: person, name: reciprocal_name)
    end
  end

  def reciprocal_name
    RECIPROCAL_RELATIONSHIP_NAMES[name][person.gender]
  end

  def can_auto_reciprocate?
    !reciprocal_name.nil?
  end

  def self.other_names
    connection.select_values("select distinct other_name from relationships where other_name is not null and other_name != '' and site_id=#{Site.current.id} order by other_name")
  end

  after_save :update_relationships_hash
  after_destroy :update_relationships_hash
  def update_relationships_hash
    person.update_relationships_hash!
  end

  RECIPROCAL_RELATIONSHIP_NAMES = {
    'aunt'            => { 'Male' => 'nephew',         'Female' => 'niece'           },
    'brother'         => { 'Male' => 'brother',        'Female' => 'sister'          },
    'brother_in_law'  => { 'Male' => 'brother_in_law', 'Female' => 'sister_in_law'   },
    'cousin'          => { 'Male' => 'cousin',         'Female' => 'cousin'          },
    'daughter'        => { 'Male' => 'father',         'Female' => 'mother'          },
    'daughter_in_law' => { 'Male' => 'father_in_law',  'Female' => 'mother_in_law'   },
    'father'          => { 'Male' => 'son',            'Female' => 'daughter'        },
    'father_in_law'   => { 'Male' => 'son_in_law',     'Female' => 'daughter_in_law' },
    'granddaughter'   => { 'Male' => 'grandfather',    'Female' => 'grandmother'     },
    'grandfather'     => { 'Male' => 'grandson',       'Female' => 'granddaughter'   },
    'grandmother'     => { 'Male' => 'grandson',       'Female' => 'granddaughter'   },
    'grandson'        => { 'Male' => 'grandfather',    'Female' => 'grandmother'     },
    'husband'         => {                             'Female' => 'wife'            },
    'mother'          => { 'Male' => 'son',            'Female' => 'daughter'        },
    'mother_in_law'   => { 'Male' => 'son_in_law',     'Female' => 'daughter_in_law' },
    'nephew'          => { 'Male' => 'uncle',          'Female' => 'aunt'            },
    'niece'           => { 'Male' => 'uncle',          'Female' => 'aunt'            },
    'other'           => {                                                           },
    'sister'          => { 'Male' => 'brother',        'Female' => 'sister'          },
    'sister_in_law'   => { 'Male' => 'brother_in_law', 'Female' => 'sister_in_law'   },
    'son'             => { 'Male' => 'father',         'Female' => 'mother'          },
    'son_in_law'      => { 'Male' => 'father_in_law',  'Female' => 'mother_in_law'   },
    'stepbrother'     => { 'Male' => 'stepbrother',    'Female' => 'stepsister'      },
    'stepdaughter'    => { 'Male' => 'stepfather',     'Female' => 'stepmother'      },
    'stepfather'      => { 'Male' => 'stepson',        'Female' => 'stepdaughter'    },
    'stepmother'      => { 'Male' => 'stepson',        'Female' => 'stepdaughter'    },
    'stepsister'      => { 'Male' => 'stepbrother',    'Female' => 'stepsister'      },
    'stepson'         => { 'Male' => 'stepfather',     'Female' => 'stepmother'      },
    'uncle'           => { 'Male' => 'nephew',         'Female' => 'niece'           },
    'wife'            => { 'Male' => 'husband'                                       }
  }.freeze
end
