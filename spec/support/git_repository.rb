require 'fileutils'
require 'pathname'
require 'tmpdir'

module SpecSupport
  class GitRepository
    def create
      @path = Pathname.new(Dir.mktmpdir)
      exec "git init"
    end

    def destroy
      FileUtils.remove_entry_secure(@path) if @path
    end

    def create_commit(task, script)
      exec "echo 'task(:#{task}) { #{script} }' > Rakefile"
      exec "git add ."
      exec "git commit -m'#{task} #{script}'"
    end

    def url
      @path
    end

    def project_name
      File.basename(url)
    end

    def filenames
      paths_in_repo = Dir.glob(url.join('*'))
      filenames_in_repo = paths_in_repo.map &File.public_method(:basename)
    end

    private

    def exec(cmd)
      `cd #{@path}; #{cmd}`.strip
    end
  end
end
