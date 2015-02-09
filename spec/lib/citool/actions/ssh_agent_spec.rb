require 'spec_helper'
require 'yaml'

describe Vx::Citool::Actions do
  let(:ssh_dir) { File.expand_path 'spec/tmp' }
  let(:pid) do
    subject.data[:pid]
  end

  let(:args) do
    file["tasks"][0]["ssh_agent"]
  end

  let(:vars) do
    file["vars"]
  end

  after do
    puts "Shutting down ssh-agent with pid #{pid}..."
    Process.kill(:KILL, pid)
    Process.wait(pid)
  end

  subject do
    described_class.extend described_class
    described_class.invoke_ssh_agent(args, ssh_dir: ssh_dir, vars: vars)
  end

  context 'Success' do
    %w(string array).each do |kind|
      context "#{kind}" do
        let!(:file) do
          path = File.expand_path "spec/fixtures/keys_#{kind}.yml"
          YAML.load_file(path)[0]
        end

        it "creates and adds ssh keys" do
          s = subject

          n = kind == "array" ? 3 : 1
          n.times do |i|
            name = "id_rsa#{i + 1}"
            expect(File).to exist(File.expand_path ssh_dir, name)
            expect(File).to exist(File.expand_path ssh_dir, "#{name}.pub")
            expect(`ssh-add -l`).to match %r[#{name}]
            expect(s).to be_instance_of(Vx::Citool::Actions::Succ)
          end
        end
      end
    end
  end

  context 'Fail' do
    let!(:file) do
      path = File.expand_path "spec/fixtures/keys_array.yml"
      YAML.load_file(path)[0]
    end

    it 'returns fail if failed' do
      stub(described_class).invoke_shell do
        Vx::Citool::Actions::Fail.new(2, "Error")
      end

      s = subject

      expect(s).to be_instance_of(Vx::Citool::Actions::Fail)
      expect(s.code).to eq 2
      expect(s.message).to eq "Error"
    end
  end
end