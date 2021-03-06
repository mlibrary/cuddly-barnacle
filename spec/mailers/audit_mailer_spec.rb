# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditMailer, type: :mailer do
  let(:package_user) { double(:package_user, email: Faker::Internet.email) }
  let(:package) do
    double(:package,
      user: package_user,
      content_type: Faker::Lorem.word,
      external_id: SecureRandom.uuid)
  end
  let(:mailer) { described_class }
  let(:email) { ActionMailer::Base.deliveries.last }
  let(:addressee) { "somebody@example.com" }
  let(:error) { Faker::Lorem.sentence }

  describe "#failure" do
    let(:mail_failure) do
      mailer.failure(emails: [addressee], package: package, error: error).deliver_now
    end

    it "sends an email" do
      expect { mail_failure }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "sends the email to the users" do
      mail_failure
      expect(email.to).to include(addressee)
    end

    it "sends the email to the package owner" do
      mail_failure
      expect(email.to).to include(package_user.email)
    end

    it "sends the email with the subject Audit Failure" do
      mail_failure
      expect(email.subject).to match(/Audit Failure/)
    end

    it "sends the email with the error detail in the body" do
      mail_failure
      expect(email.body.encoded).to match(error)
    end

    it "lists the package external id in the subject" do
      mail_failure
      expect(email.subject).to match(package.external_id)
    end

    it "lists the package content type in the subject" do
      mail_failure
      expect(email.subject).to match(package.content_type)
    end

    it "sends the email to the configured from address" do
      mail_failure
      expect(email.from).to contain_exactly(Chipmunk.config.default_from)
    end
  end
end
