require 'tmpdir'
require 'fileutils'

module Paraboard
  class Registry
    attr_accessor :base_dir
    def initialize(base_dir: nil)
      @base_dir = base_dir || raise ArgumentError, "required base_dir"
      FileUtils.mkpath(@base_dir) unless Dir.exist?(@base_dir)
    end

    def update(status)
      name = build_filename
      tmp  = "#{name}.tmp"
      f = open(tmp, "w+")
      f.flock(File::LOCK_EX)
      f.print(status)
      f.flock(File::LOCK_UN)
      f.close
      File.rename(tmp, name)
    end

    def read_all
      ret = {}
      files = Dir.glob("#{base_dir}/**")
      files.each do |file|
        next unless file =~ /\/status_(.*)/
        id = $1
        f = open(file, "r+")
        ret[id] = f.read
      end
      ret
    end

    private
    def worker_id
      $$
    end

    def build_filename
      "#{base_dir}/status_#{worker_id}"
    end
  end
end
