module Vx
  module Citool
    module Actions

      def invoke_git_clone(args, options = {})
        args = extract_keys(args, :repo, :dest, :sha, :branch, :pr)

        cmd = "git clone --depth=50"

        if args[:branch] and !args[:pr]
          cmd << " --branch #{args[:branch]}"
        end

        cmd << " #{args[:repo]} #{args[:dest]}"

        unless args[:dest].to_s.strip != ""
          re = invoke_shell("rm -rf #{args[:dest]}", silent: true, hidden: true)
        end

        re = invoke_shell(cmd)
        return re unless re.success?

        if pr = args[:pr]
          re = invoke_shell("git fetch origin +refs/pull/#{pr}/head chdir=#{args[:dest]}")
          return re unless re.success?

          re = invoke_shell("git checkout -q FETCH_HEAD chdir=#{args[:dest]}")
          return re unless re.success?
        else
          re = invoke_shell("git checkout -qf #{args[:sha]} chdir=#{args[:dest]}")
          return re unless re.success?
        end

        re
      end
    end

  end
end
