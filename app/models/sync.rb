class Sync < ActiveRecord::Base
  belongs_to :site
  scope_by_site_id

  belongs_to :person
  has_many :sync_items, dependent: :delete_all
  has_many :people,   through: :sync_items, source: :syncable, source_type: 'Person'
  has_many :families, through: :sync_items, source: :syncable, source_type: 'Family'
  has_many :groups,   through: :sync_items, source: :syncable, source_type: 'Group'

  def total_count
    success_count.to_i + error_count.to_i
  end

  def success_rate
    if !complete?
      nil
    elsif total_count > 0
      success_count.to_i / total_count.to_f * 100.0
    else
      100.0
    end
  end

  def count_items
    {
      create: sync_items.creates.count,
      update: sync_items.updates.count,
      error:  sync_items.errors.count
    }.reject { |k, v| v == 0 }
  end
end
