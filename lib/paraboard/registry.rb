require 'tmpdir'
require 'fileutils'

module Paraboard
  class Registry
    attr_accessor :base_dir, :worker_id, :fh, :pid_for_fh
    def initialize(base_dir: nil)
      @base_dir = base_dir or raise ArgumentError, "required base_dir"
      @worker_id = -> { Process.pid }
      FileUtils.mkpath(@base_dir) unless Dir.exist?(@base_dir)
    end

    def update(status)
      pid = worker_id.call
      if fh && pid_for_fh != pid
        fh.close
        self.fh = nil
      end

      unless fh
        name = build_filename
        tmp  = "#{name}.tmp"
        f = open(tmp, "w")
        f.flock(File::LOCK_EX)
        File.rename(tmp, name)
        self.fh = f
        self.pid_for_fh = pid
      end

      fh.rewind
      fh.print(status)
      fh.flush
    end

    def read_all
      ret = {}
      for_all do |pid, f|
        ret[pid] = f.read
      end
      ret
    end

    private
    def for_all(&callback)
      files = Dir.glob("#{base_dir}/**")
      files.each do |fn|
        next unless fn =~ /\/status_([0-9]*)$/
        pid = $1

        # tmpがある時に見て、消えるとかある
        f = open(fn, "r") rescue next

        # 既に終わってるプロセスは閉じて、消す
        if pid != worker_id.call && f.flock(File::LOCK_EX | File::LOCK_NB)
          begin
            f.close
            File.unlink(fn)
          rescue => e
            # 消すのに失敗したらログを出す
            warn "failed to remove an obsolete scoreboard file:#{fn}:#{e}"
          ensure
            next
          end
        end

        callback.call(pid, f)
        f.close
      end
    end

    def build_filename
      "#{base_dir}/status_#{worker_id.call}"
    end
  end
end
