require_relative '../rails_helper'

describe Verse do
  before do
    @verse = Verse.create(reference: '1 John 1:9', text: 'If we confess our sins, he is faithful and righteous to forgive us the sins, and to cleanse us from all unrighteousness.')
  end

  it 'should find an existing verse by reference' do
    v = Verse.find(@verse.reference)
    expect(v).to eq(@verse)
  end

  it 'should find an existing verse by id' do
    v = Verse.find(@verse.id)
    expect(v).to eq(@verse)
  end

  context 'given a new verse' do
    let(:payload) do
      {
        'reference' => 'John 3:16',
        'text'      => 'For God so loved the world, that he gave his one and only Son, that whoever believes in him should not perish, but have eternal life.'
      }
    end

    before do
      expect(Verse).to receive(:fetch).with('jn 3:16') { payload }
      expect(Verse).to receive(:fetch).with('John 3:16') { payload }
      @verse = Verse.find('jn 3:16')
    end

    it 'normalizes the reference' do
      expect(@verse.reference).to eq('John 3:16')
    end

    it 'sets the verse text' do
      expect(@verse.text).to eq(payload['text'])
    end

    it 'updates the sortables' do
      expect(@verse.book).to    eq(42)
      expect(@verse.chapter).to eq(3)
      expect(@verse.verse).to   eq(16)
    end
  end

  describe '#normalize' do
    it 'normalizes the reference' do
      expect(Verse).to receive(:fetch).with('ii chronicles 10:1') do
        {
          'reference' => '2 Chronicles 10:1',
          'text'      => '...'
        }
      end
      expect(Verse.normalize_reference('ii chronicles 10:1')).to eq('2 Chronicles 10:1')
    end
  end

  describe '#fetch' do
    let(:payload) do
      {
        'reference' => 'John 3:16',
        'text'      => 'For God so loved the world, that he gave his one and only Son, that whoever believes in him should not perish, but have eternal life.'
      }
    end

    before do
      stub_request(:get, "http://bible-api.com/John%203:16?translation=web")
        .to_return(body: payload.to_json)
    end

    it 'sends a request to bible-api.com' do
      expect(Verse.fetch('John 3:16')).to match(payload)
    end
  end
end
