require 'rails_helper'

describe GeocoderJob do
  let(:family) do
    FactoryGirl.create(
      :family,
      address1: '650 S. Peoria',
      city: 'Tulsa',
      state: 'OK',
      zip: '74120',
      country: 'US',
      dont_geocode: true
    )
  end

  describe '#perform' do
    context 'given a proper response from the geocoding service' do
      before do
        Geocoder::Lookup::Test.add_stub(
          '650 S. Peoria, Tulsa, OK, 74120, US', [
            {
              'latitude'     => 36.151305,
              'longitude'    => -95.975393,
              'address'      => 'Tulsa, OK, USA',
              'state'        => 'Oklahoma',
              'state_code'   => 'OK',
              'country'      => 'United States',
              'country_code' => 'US'
            }
          ]
        )
        subject.perform(Site.current, 'Family', family.id)
      end

      it 'updates the latitude and longitude' do
        expect(family.reload.attributes).to include(
          'latitude'  => within(0.00001).of(36.151305),
          'longitude' => within(0.00001).of(-95.975393)
        )
      end
    end

    context 'given a timeout error from the geocoding service' do
      before do
        allow(subject).to receive(:sleep)
        call_count = 0
        allow(Geocoder).to receive(:search) do
          call_count += 1
          if call_count < 3
            raise Geocoder::OverQueryLimitError
          else
            [double('result', latitude: 36.151305, longitude: -95.975393)]
          end
        end
        subject.perform(Site.current, 'Family', family.id)
      end

      it 'sleeps for a time before trying again' do
        expect(subject).to have_received(:sleep).with(1).twice
        expect(Geocoder).to have_received(:search).exactly(3).times
      end

      it 'updates the latitude and longitude' do
        expect(family.reload.attributes).to include(
          'latitude'  => within(0.00001).of(36.151305),
          'longitude' => within(0.00001).of(-95.975393)
        )
      end
    end

    context 'given a general error from the geocoding service' do
      before do
        allow(subject).to receive(:sleep)
        call_count = 0
        allow(Geocoder).to receive(:search) do
          call_count += 1
          if call_count <= error_count
            raise Geocoder::RequestDenied
          else
            [double('result', latitude: 36.151305, longitude: -95.975393)]
          end
        end
      end

      context 'the error happens twice' do
        let(:error_count) { 2 }

        before do
          subject.perform(Site.current, 'Family', family.id)
        end

        it 'sleeps twice before trying again' do
          expect(subject).to have_received(:sleep).with(1).twice
          expect(Geocoder).to have_received(:search).exactly(3).times
        end

        it 'updates the latitude and longitude' do
          expect(family.reload.attributes).to include(
            'latitude'  => within(0.00001).of(36.151305),
            'longitude' => within(0.00001).of(-95.975393)
          )
        end
      end

      context 'the error happens three times' do
        let(:error_count) { 3 }

        it 'fails' do
          expect do
            subject.perform(Site.current, 'Family', family.id)
          end.to raise_error(GeocoderJob::GeocodingError)
        end

        it 'does not update the latitude and longitude' do
          expect(family.reload.attributes).to include(
            'latitude'  => nil,
            'longitude' => nil
          )
        end
      end
    end
  end
end
