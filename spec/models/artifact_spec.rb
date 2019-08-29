require "rails_helper"

RSpec.describe Artifact, type: :model do
  let(:id) { SecureRandom.uuid }
  let(:user) { Fabricate.create(:user) }
  let(:content_type) { ["digital", "audio"].sample }
  let(:format) { ["bag", "bag:versioned"].sample }

  it "has a valid fabricator" do
    expect(Fabricate.create(:artifact)).to be_valid
  end

  it "has a valid fabriactor that doesn't save to the database" do
    expect(Fabricate.build(:artifact)).to be_valid
  end

  describe "#id" do
    it "must be unique" do
      expect do
        2.times { Fabricate(:artifact, id: id) }
      end.to raise_error ActiveRecord::RecordNotUnique
    end
  end

  it "can be something other than a uuid" do
    expect { Fabricate(:artifact, id: "foo") }.to_not raise_error
  end

  describe "#stored?" do
    it "is false if there are exactly zero revisions" do
      expect(Fabricate.build(:artifact, revisions: []).stored?).to be false
    end
    it "is true if it has 1 or more revisions" do
      artifact = Fabricate.build(
        :artifact,
        revisions: [ Fabricate.build(:revision) ]
      )
      expect(artifact.stored?).to be true
    end
  end

end
