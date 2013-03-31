DB.create_table :projects do
  primary_key :id
  String :name
  String :activity
  String :repository_url
  Boolean :ready
end

DB.create_table :builds do
  primary_key :id
  foreign_key :project_id, :projects
  String :status
  DateTime :started_at
  DateTime :completed_at
end

