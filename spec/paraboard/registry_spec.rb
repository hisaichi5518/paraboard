require 'spec_helper'
require 'paraboard/registry'
require 'tmpdir'

class ParaboardRegistryTester
  attr_accessor :tmpdir, :registry
  def initialize
    @tmpdir = Dir.mktmpdir
    @registry = Paraboard::Registry.new(base_dir: @tmpdir)
  end

  def execute
    registry = @registry
    pid = fork do
      registry.update("updated")
      sleep 2
    end
    # 1度書き込まれるのを待つ
    sleep 1
    pid
  end
end

describe Paraboard::Registry do
  let :tester do
    ParaboardRegistryTester.new
  end

  describe "#update" do
    before do
      @pid = tester.execute
    end

    it "locked file" do
      f = open(tester.tmpdir + "/status_#{@pid}", "w+")
      result = f.flock(File::LOCK_EX | File::LOCK_NB)
      expect(result).to eq false
      f.close
    end
  end

  describe "#read_all" do
    before do
      @pid = tester.execute
    end

    context "having status file" do
      it "returns pid and status" do
        expect(tester.registry.read_all).to eq(@pid.to_s => "updated")
      end
    end

    context "not have status file" do
      it "returns empty hash" do
        Process.wait(@pid)
        expect(tester.registry.read_all).to eq({})
      end
    end
  end
end
