# frozen_string_literal: true

require "rails_helper"

RSpec.describe V1::PackagesController, type: :controller do
  describe "/v1" do
    describe "GET #index" do
      it_behaves_like "an index endpoint" do
        let(:key) { :bag_id }
        let(:factory) do
          proc {|user| user ? Fabricate(:package, user: user) : Fabricate(:package) }
        end
        let(:assignee) { :packages }
      end
    end

    describe "GET #show" do
      it_behaves_like "a show endpoint" do
        let(:key) { :bag_id }
        let(:factory) do
          proc {|user| user ? Fabricate(:package, user: user) : Fabricate(:package) }
        end
        let(:assignee) { :package }
      end
    end

    describe "GET #sendfile" do
      include_context "as underprivileged user"

      context "with mocked storage" do
        let(:package) { Fabricate(:package, user: user, storage_location: '/foo') }
        let(:bag) { double(:bag, data_dir: '/foo/data', bag_files: ['/foo/data/samplefile.jpg'] ) }
        let(:storage) { double(:storage, new: bag) }

        before(:each) do
          @old_storage = Services.storage
          Services.register(:storage) { storage }
        end

        after(:each) do
          Services.register(:storage) { @old_storage }
        end

        let(:service) { described_class.new(package, storage: storage) }

        # needs the full rack stack to test X-Sendfile; see requests/v1/packages_file_spec.rb
        # it "can retrieve a file from the package"

        it "returns a 404 if the file isn't present in the bag" do
          get :sendfile, params: { bag_id: package.bag_id, file: "nonexistent" }

          expect(response).to have_http_status(404)
        end
        
        # so painful
        it "checks PackagePolicy with the show? action" do
          policy = double(:policy)
          allow(PackagePolicy).to receive(:new).with(user,package).and_return(policy)
          allow(controller).to receive(:send_file).and_return(nil)
          expect(policy).to receive(:authorize!).with(:show?)

          get :sendfile, params: { bag_id: package.bag_id, file: "samplefile.jpg" }
        end

      end
      
    end

    describe "GET #show/:external_id" do
      include_context "as underprivileged user"
      let(:package) { Fabricate(:package, user: user) }

      it "can fetch a package by external id" do
        get :show, params: { bag_id: package.external_id }

        expect(assigns(:package)).to eql(package)
      end
    end

    describe "POST #create" do
      let(:attributes) do
        {
          bag_id:       SecureRandom.uuid,
          content_type: "audio",
          external_id:  SecureRandom.uuid
        }
      end

      shared_context "mocked RequestBuilder" do |status|
        let(:result_request) do
          Fabricate(:package,
            bag_id: attributes[:bag_id],
            user: user,
            external_id: attributes[:external_id],
            content_type: attributes[:content_type])
        end
        let(:result_status) { status }
        let(:builder) { double(:builder) }
        before(:each) do
          allow(RequestBuilder).to receive(:new).and_return(builder)
          allow(builder).to receive(:create).and_return([result_status, result_request])
        end
      end

      context "as authenticated user" do
        include_context "as underprivileged user"
        context "new record" do
          context "RequestBuilder returns a valid record" do
            include_context "mocked RequestBuilder", :created

            it "passes the parameters to a RequestBuilder" do
              post :create, params: attributes
              expect(RequestBuilder).to have_received(:new)
              expect(builder).to have_received(:create).with(attributes.merge(user: user))
            end
            it "returns 201" do
              post :create, params: attributes
              expect(response).to have_http_status(201)
            end
            it "correctly sets the location header" do
              post :create, params: attributes
              expect(response.location).to eql(v1_request_path(result_request))
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
          context "RequestBuilder returns an invalid record" do
            include_context "mocked RequestBuilder", :invalid
            it "returns 422" do
              post :create, params: attributes
              expect(response).to have_http_status(422)
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
        end
        context "as duplicate record" do
          include_context "mocked RequestBuilder", :duplicate
          it "does not create an additional record" do
            post :create, params: attributes
            expect(Package.count).to eql(1)
          end
          it "returns 303" do
            post :create, params: attributes
            expect(response).to have_http_status(303)
          end
          it "correctly sets the location header" do
            post :create, params: attributes
            expect(response.location).to eql(v1_request_path(result_request))
          end
          it "renders nothing" do
            post :create, params: attributes
            expect(response).to render_template(nil)
          end
        end
      end
    end
  end
end
