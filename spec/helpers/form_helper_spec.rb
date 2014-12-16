require_relative '../rails_helper'

describe FormHelper, type: :helper do
  let(:user) { FactoryGirl.build(:person, birthday: Date.new(1981, 4, 28), mobile_phone: '9181234567') }

  describe 'date_field and date_field_tag' do
    it 'outputs a text field with placeholder and formatted date' do
      Setting.set(:formats, :date, '%m/%d/%Y')
      OneBody.set_local_formats
      expect(date_field_tag(:birthday, Date.new(1981, 4, 28))).to eq(
        '<input class="date-field" id="birthday" name="birthday" placeholder="MM/DD/YYYY" type="text" value="04/28/1981" />'
      )
      form_for(user) do |form|
        expect(form.date_field(:birthday)).to eq(
          '<input class="date-field" id="person_birthday" name="person[birthday]" placeholder="MM/DD/YYYY" type="text" value="04/28/1981" />'
        )
      end
    end

    it 'handles nil and empty string' do
      user.birthday = nil
      expect(date_field_tag(:birthday, "")).to eq('<input class="date-field" id="birthday" name="birthday" placeholder="MM/DD/YYYY" type="text" value="" />')
      form_for(user) do |form|
        expect(form.date_field(:birthday)).to eq('<input class="date-field" id="person_birthday" name="person[birthday]" placeholder="MM/DD/YYYY" type="text" />')
      end
    end
  end

  describe 'phone_field' do
    it 'outputs a text field' do
      form_for(user) do |form|
        expect(form.phone_field(:mobile_phone)).to eq("<input id=\"person_mobile_phone\" name=\"person[mobile_phone]\" size=\"15\" type=\"text\" value=\"(918) 123-4567\" />")
      end
    end
  end

end
