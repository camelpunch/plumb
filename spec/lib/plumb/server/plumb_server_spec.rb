require_relative "../../../../spec/server_spec_helper"

module Plumb
  describe Server do
    include Rack::Test::Methods
    include ServerSpecHelpers

    describe "putting a new project" do
      it "is reflected in the CCTray XML feed" do
        id = SecureRandom.uuid
        put_project id, name: 'PUTting a new project'
        last_response.status.must_equal 200

        project_xml('PUTting a new project')['lastBuildStatus'].
          must_equal 'Unknown'
      end
    end

    describe "putting an existing project" do
      it "updates the project" do
        id = SecureRandom.uuid
        put_project id, name: 'My New Project'
        put_project id, name: 'My Renamed Project'

        project_xml('My Renamed Project')['lastBuildStatus'].
          must_equal 'Unknown'
      end
    end

    describe "getting a project" do
      it "uses the JSON content type" do
        id = SecureRandom.uuid
        put_project id, name: 'Unit Tests'
        get "/projects/#{id}"
        last_response.content_type.must_include 'application/json'
      end
    end

    describe "putting a new build on a project" do
      let(:new_name) { SecureRandom.hex }

      it "is reflected in the CCTray XML feed" do
        project_id = SecureRandom.uuid
        build_id = SecureRandom.uuid

        put_project project_id, name: new_name
        put_build project_id, build_id, status: "Success", completed_at: '2013-01-01 00:00'

        xml = project_xml(new_name)
        xml['lastBuildStatus'].must_equal 'Success'
        xml['activity'].must_equal 'Sleeping'
        xml['webUrl'].must_equal "http://example.org/cc.xml"
      end

      it "responds with success JSON" do
        project_id = SecureRandom.uuid
        build_id = SecureRandom.uuid

        put_project project_id, name: new_name
        put_build project_id, build_id, status: "Success", completed_at: '2013-01-01 00:00'

        last_response.status.must_equal 200
        last_response.body.must_equal '{}'
        last_response.content_type.must_include 'application/json'
      end
    end

    describe "putting an existing build on a project" do
      it "is reflected in the CCTray XML feed" do
        project_id = SecureRandom.uuid
        build_id = SecureRandom.uuid

        put_project project_id, name: 'Existence'
        put_build project_id, build_id,
          status: "Building", started_at: '2013-01-01 00:00'
        put_build project_id, build_id,
          status: "Success", completed_at: '2013-01-02 00:00'

        project_xml('Existence')['lastBuildStatus'].must_equal 'Success'
      end
    end

    describe "putting another project's build ID on a project" do
      it "409s and doesn't update existing build" do
        project_id_1 = SecureRandom.uuid
        project_id_2 = SecureRandom.uuid
        build_id = SecureRandom.uuid

        put_project project_id_1, name: 'Project1'
        put_project project_id_2, name: 'Project2'
        put_build project_id_1, build_id,
          status: "Building", started_at: '2013-01-01 00:00'

        put_build project_id_2, build_id,
          status: "Success", completed_at: '2013-01-02 00:00'
        last_response.status.must_equal 409

        project_xml('Project1')['activity'].must_equal 'Building'
      end
    end

    describe "getting the CCTray XML feed" do
      it "uses the XML content type" do
        get_dashboard
        last_response.content_type.must_include 'text/xml'
      end

      it "always gives a 200" do
        get_dashboard
        last_response.status.must_equal 200
      end

      it "includes the latest build's ID as its label" do
        put_project 'someproject', name: 'Get build label'
        put_build 'someproject', 'mybuildid', status: "Success"
        last_build_label_for_project('Get build label').must_equal 'mybuildid'
      end
    end
  end
end
