---
title: Using Rails Event Store with Protobuf
---

Using RES with Protobuf or another binary serialization protocol might be a good idea if you want to share your events' data with another applications and micro-services.

## Installation

Add RES and protobuf to your app's `Gemfile`

```ruby
gem 'google-protobuf'
gem 'protobuf_nested_struct'
gem 'rails_event_store'
```

## Migration

Change `data` and `metadata` columns' type to `binary` to allow storing
non-UTF8 characters which might appear when using protobuf serialization.

```ruby
change_column :event_store_events, :data,     :binary, null: true
change_column :event_store_events, :metadata, :binary, null: true
```

## Configure protobuf mapper

```ruby
Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new(
      mapper: RubyEventStore::Mappers::Protobuf.new
    )
  end
end
```

## Defining events

Define your events in protobuf file format i.e.: `events.proto3`

```
syntax = "proto3";
package my_app;

message OrderPlaced {
  string order_id = 1;
  int32 customer_id = 2;
}
```

and generate the Ruby classes:

```ruby
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: events.proto3

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "my_app.OrderPlaced" do
    optional :order_id, :string, 1
    optional :customer_id, :int32, 2
  end
end

module MyApp
  OrderPlaced = Google::Protobuf::DescriptorPool.generated_pool.lookup("my_app.OrderPlaced").msgclass
end
```

## Publishing

```ruby
event_store = Rails.configuration.event_store

event = RubyEventStore::Proto.new(
  data: MyApp::OrderPlaced.new(
    order_id: "K3THNX9",
    customer_id: 123,
  )
)
event_store.publish(event, stream_name: "Order-K3THNX9")
```

## Retrieving

```ruby
event = client.read.stream('test').last
```

## Subscribing

#### Sync handlers

```ruby
event_store.subscribe(->(ev){ },  to: [MyApp::OrderPlaced.descriptor.name])
```

#### Async handlers

```ruby
class SendOrderEmailHandler < ActiveJob::Base
  self.queue_adapter = :inline

  def perform(payload)
    event = event_store.deserialize(payload)
    # do something
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end

event_store.subscribe(SendOrderEmailHandler, to: [MyApp::OrderPlaced.descriptor.name])
```