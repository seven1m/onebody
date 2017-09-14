require 'rails_helper'

describe Date, type: :model do
  it 'should parse date with year first' do
    expect(Time.parse('2013-01-02').strftime('%b %d, %Y')).to eq('Jan 02, 2013')
    expect(Date.parse('2013-01-02').strftime('%b %d, %Y')).to eq('Jan 02, 2013')
    expect(Time.parse('2013-01-02 13:01').strftime('%b %d, %Y %I:%M %p')).to eq('Jan 02, 2013 01:01 PM')
    expect(DateTime.parse('2013-01-02 13:01').strftime('%b %d, %Y %I:%M %p')).to eq('Jan 02, 2013 01:01 PM')
  end

  it 'should parse american dates' do
    Setting.set(1, 'Formats', 'Date', '%m/%d/%Y')
    expect(Date.parse_in_locale('01/02/2013').strftime('%b %d, %Y')).to eq('Jan 02, 2013')
    expect(Date.parse_in_locale('1/2/2013').strftime('%b %d, %Y')).to eq('Jan 02, 2013')
  end

  it 'should parse european dates' do
    Setting.set(1, 'Formats', 'Date', '%d/%m/%Y')
    expect(Date.parse_in_locale('02/01/2013').strftime('%b %d, %Y')).to eq('Jan 02, 2013')
    expect(Date.parse_in_locale('2/1/2013').strftime('%b %d, %Y')).to eq('Jan 02, 2013')
    Setting.set(1, 'Formats', 'Date', '%m/%d/%Y') # put this back
  end
end
