require 'sequel'
require 'logger'
DB = Sequel.sqlite(logger: Logger.new('log/test_db.log'))
