class Update < ActiveRecord::Base

  belongs_to :person
  belongs_to :site

  scope_by_site_id

  scope :pending, -> { where(complete: false) }
  scope :complete, -> { where(complete: true) }

  serialize :data

  def apply!
    person.update_attributes!(data[:person])
    family.update_attributes!(data[:family])
  end

  def family
    person.try(:family)
  end

  def self.daily_counts(limit, offset, date_strftime='%Y-%m-%d', only_show_date_for=nil)
    [].tap do |data|
      counts = connection.select_all("select count(date(created_at)) as count, date(created_at) as date from updates where site_id=#{Site.current.id} group by date(created_at) order by created_at desc limit #{limit} offset #{offset};").group_by { |p| Date.parse(p['date'].strftime('%Y-%m-%d')) }
      ((Date.today-offset-limit+1)..(Date.today-offset)).each do |date|
        d = date.strftime(date_strftime)
        d = ' ' if only_show_date_for and date.strftime(only_show_date_for[0]) != only_show_date_for[1]
        count = counts[date] ? counts[date][0]['count'].to_i : 0
        data << [d, count]
      end
    end
  end

end
