# Monitor the number of database servers in each state
#
# Useful to see how many databases are ONLINE
#
# Created by Eric Lindvall <eric@sevenscale.com>
#

class MysqlMmm < Scout::Plugin
  OPTIONS=<<-EOS
  command:
    name: Status command
    notes: The status command to invoke
    default: sudo mmm_control show
  EOS

  def build_report
    command = option('command') || 'sudo mmm_control show'

    show = IO.popen(command) do |io|
      io.read
    end

    result = parse_mmm_control_show(show)

    report result
  end

  def parse_mmm_control_show(show)
    result = Hash.new { |h,k| h[k] = 0 }

    show.split(/\n+/).each do |line|
      if line =~ %r{^\s+\S+? (\w+/\w+)\. Roles: .*}
        result[$1] += 1
      end
    end

    result
  end
end