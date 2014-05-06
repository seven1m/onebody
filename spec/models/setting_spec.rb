require_relative '../spec_helper'

describe Setting do

  context 'Field Types' do

    it "should return an array for settings of type 'lines'" do
      Setting.set(1, 'Features', 'Custom Person Fields', ['Text', 'A Date'].join("\n"))
      expect(Setting.get(:features, :custom_person_fields)).to eq(["Text", "A Date"])
      Setting.set(1, 'Features', 'Custom Person Fields', '')
    end

    it "should return an array for settings of type 'lines', even if empty" do
      Setting.set(1, 'Features', 'Custom Person Fields', '')
      expect(Setting.get(:features, :custom_person_fields)).to eq([])
    end

  end

end
