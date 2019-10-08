require 'spec_helper'

module RubyEventStore
  module Mappers
    module Transformation
      RSpec.describe DomainEvent do
        let(:uuid)  { SecureRandom.uuid }
        let(:time)  { Time.now.utc }
        let(:event) {
          TimestampEnrichment.with_timestamp(
            TestEvent.new(
              event_id: uuid,
              data: { some: 'value' },
              metadata: { some: 'meta' }
            ),
            time
          )
        }
        let(:item)  {
          Item.new(
            event_id:   uuid,
            metadata:   {some: 'meta'},
            data:       {some: 'value'},
            event_type: 'TestEvent',
            timestamp:  time
          )
        }

        specify "#dump" do
          expect(DomainEvent.new.dump(event)).to eq(item)
        end

        specify "#load" do
          loaded = DomainEvent.new.load(item)
          expect(loaded).to eq(event)
          expect(loaded.metadata.to_h).to eq(event.metadata.to_h)
        end
      end
    end
  end
end
