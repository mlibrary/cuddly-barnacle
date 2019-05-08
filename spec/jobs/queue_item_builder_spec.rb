# frozen_string_literal: true

require "rails_helper"

RSpec.describe QueueItemBuilder do
  let(:config_upload_path) { Rails.application.config.upload["upload_path"] }
  let(:config_storage_path) { Rails.application.config.upload["storage_path"] }

  before(:each) do
    allow(BagMoveJob).to receive(:perform_later)
  end

  shared_examples "a QueueItemBuilder invocation that returns a duplicate" do
    it "returns :duplicate" do
      expect(status).to eql(:duplicate)
    end
    it "returns the duplicate queue_item" do
      expect(queue_item).to eql(existing)
    end
  end

  shared_examples "a QueueItemBuilder invocation that creates a new QueueItem" do
    it "returns :created" do
      expect(status).to eql(:created)
    end
    it "returns the created queue_item" do
      expect(queue_item).to be_an_instance_of(QueueItem)
    end
    it "the queue_item belongs to the request" do
      expect(queue_item.package).to eql(request)
    end
    it "the queue_item is pending" do
      expect(queue_item.pending?).to be true
    end
    it "enqueues a BagMoveJob to /<storage_path>/:bag_id" do
      expect(BagMoveJob).to have_received(:perform_later).with(queue_item)
    end
  end

  describe "#create" do
    let(:request) { Fabricate(:request) }

    let(:status_item) { described_class.new.create(request) }
    let(:status) { status_item[0] }
    let(:queue_item) { status_item[1] }

    context "duplicate queue_item with status==:done" do
      let!(:existing) { Fabricate(:queue_item, package: request, status: :done) }

      it_behaves_like "a QueueItemBuilder invocation that returns a duplicate"
    end

    context "duplicate queue_item with  status==:pending" do
      let!(:existing) { Fabricate(:queue_item, package: request, status: :pending) }

      it_behaves_like "a QueueItemBuilder invocation that returns a duplicate"
    end

    context "duplicate queue_item with  status==:failed" do
      let!(:existing) { Fabricate(:queue_item, package: request, status: :failed) }

      it_behaves_like "a QueueItemBuilder invocation that creates a new QueueItem"
      it "does not return the existing queue item" do
        expect(queue_item).not_to eql(existing)
      end
    end

    context "no duplicate queue_item" do
      it_behaves_like "a QueueItemBuilder invocation that creates a new QueueItem"
    end

    context "with an invalid request" do
      let(:request) { Fabricate.build(:request, external_id: nil) }

      it "returns :invalid" do
        expect(status).to eql(:invalid)
      end
      it "returns the invalid queue_item" do
        expect(queue_item).to be_an_instance_of(QueueItem)
      end
    end
  end
end