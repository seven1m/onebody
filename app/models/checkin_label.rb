class CheckinLabel < ApplicationRecord
  class InvalidCheckinLabelPath < StandardError; end

  scope_by_site_id

  validates :name, :xml, presence: true

  def xml
    if self[:xml] =~ /<file\s+src/i
      doc = Nokogiri::XML(self[:xml])
      filename = doc.css('file')[0]['src']
      raise InvalidCheckinLabelPath, 'file unavailable' if filename =~ /\.\.|\A\/|\A\\/
      path = Rails.root.join('db/checkin/labels', filename)
      raise InvalidCheckinLabelPath, 'file not found' unless File.exist?(path)
      File.read(path, encoding: 'utf-8')
    else
      self[:xml]
    end
  end

  def xml_file=(f)
    self.xml = f.read
  end
end
