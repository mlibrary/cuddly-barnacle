# frozen_string_literal: true

# Given a hash of parameters, this builds a request of an
# appropriate type. It does the following:
#
# Contacts third-party services to ensure metadata is present and accurate.
# Provisions a location for the file to be uploaded
# Populates the upload_link field of the request
#
# This process is synchronous.
class RequestBuilder
  def create(bag_id:, content_type:, external_id:, user:)
    duplicate = Package.find_by_bag_id(bag_id)
    duplicate ||= Package.find_by_external_id(external_id)
    unless duplicate.nil?
      return :duplicate, duplicate
    end

    request = Package.new(
      bag_id: bag_id,
      external_id: external_id,
      content_type: content_type,
      user: user,
      # FIXME: This is really, really bad. To-be-ingested packages should not
      #        have a value for storage_volume until they are stored. For now,
      #        I'm doubling down because we do not yet have the behavioral
      #        notions of what's valid in request state vs. stored state or the
      #        component that manages external/temporary storage sorted out.
      storage_volume: "none"
      )
    if request.valid?
      request.save!
      return :created, request
    else
      return :invalid, request
    end
  end
end
