DB.create_table :projects do
  String :id, primary_key: true
  String :name
  String :activity
  String :repository_url
  String :script
  Boolean :ready
end

DB.create_table :builds do
  String :id, primary_key: true
  foreign_key :project_id, :projects, type: String
  String :status
  DateTime :started_at
  DateTime :completed_at
end

