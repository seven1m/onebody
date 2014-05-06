require_relative '../spec_helper'

describe Verse do
  before do
    @verse = Verse.create(reference: '1 John 1:9', text: 'test')
  end

  it "should find an existing verse by reference" do
    v = Verse.find(@verse.reference)
    expect(v.text).to eq("test")
  end

  it "should find an existing verse by id" do
    v = Verse.find(@verse.id)
    expect(v.text).to eq("test")
  end

  it "should create a verse by reference" do
    v = Verse.find('1 John 1:9')
    expect(v.text).to eq("test")
  end

  it "should link verses in a body of text" do
    text = <<-END
      Here is a verse: John 3:16.
      Mark 1:1 is another verse.
      Here is a complex verse: John 3:16-4:2
      Another complex verse: Romans 12:5-6;13:9
      Romans 12 should be NIV and
      Romans 12 (MSG) should be The Message
    END
    linked = Verse.link_references_in_text(text)
    expect(text.scan(/<a href/).length).to eq(6)
    expect(linked.index('http://bible.gospelcom.net/cgi-bin/bible?passage=Romans+12&version=NIV')).to be
    expect(linked.index('http://bible.gospelcom.net/cgi-bin/bible?passage=Romans+12&version=MSG')).to be
  end

  it "should normalize reference" do
    expect(Verse.normalize_reference("3 john 1:1")).to eq("3 John 1:1")
    expect(Verse.normalize_reference("ii chronicles 10:1")).to eq("2 Chronicles 10:1")
    expect(Verse.normalize_reference("john 3:16")).to eq("John 3:16")
    expect(Verse.normalize_reference("Song of Solomon 1:1")).to eq("Song of Solomon 1:1")
  end

end
