module Plumb
  module ProjectMapperSharedTests
    attr_reader :project_id, :build_id1, :build_id2

    def setup
      @project_id = SecureRandom.uuid
      @build_id1 = SecureRandom.uuid
      @build_id2 = SecureRandom.uuid
    end

    def project_hash(attrs = {})
      {
        id: project_id,
        name: SecureRandom.hex,
        activity: 'Sleeping',
        repository_url: nil,
        ready: nil,
        script: nil
      }.merge(attrs)
    end

    def build_hash(attrs)
      {
        id: nil,
        status: nil,
        started_at: nil,
        completed_at: nil,
        project_id: project_id
      }.merge(attrs)
    end

    def test_includes_basic_attributes_when_getting_by_id
      attributes = project_hash(
        id: project_id,
        name: 'Some Build',
        builds: []
      )

      mapper.insert(attributes)

      project = mapper.get(project_id)
      assert_equal attributes, project.to_hash
    end
  end
end

