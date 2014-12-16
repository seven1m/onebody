require_relative '../rails_helper'

describe Setting do

  context 'Field Types' do

    it "should return an array for settings of type 'list'" do
      Setting.set(1, 'System', 'Suffixes', ['Text', 'A Date'].join("\n"))
      expect(Setting.get(:system, :suffixes)).to eq(["Text", "A Date"])
      Setting.set(1, 'System', 'Suffixes', '')
    end

    it "should return an array for settings of type 'list', even if empty" do
      Setting.set(1, 'System', 'Suffixes', '')
      expect(Setting.get(:system, :suffixes)).to eq([])
    end

  end

end
