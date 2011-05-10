#
# Written by Eric Lindvall <eric@sevenscale.com>
#

class NetworkLatency < Scout::Plugin
  OPTIONS=<<-EOS
    host:
      label: Host
      notes: The remote host to measure. Defaults to the default gateway if none is specified.
    count:
      label: Count
      notes: Number of samples to take
      default: 5
  EOS

  def build_report
    measurement = measure_latency(option(:host) || default_gateway)

    report :packet_loss => measurement[:packet_loss], :average => measurement[:avg]
  end

  def measure_latency(host)
    count = option(:count) || 5
    ping = %x{/bin/ping -c #{count} -i 0.2 -q #{host}}
    ping = %x{/bin/ping -c #{count} -q #{host}} unless $?.success?

    result = {}
    result[:packet_loss] = ping[/([\d\.]+)% packet loss/, 1].to_f

    if m = ping.match(%r{^(rtt|round-trip) .* = ([\d+\.]+)/([\d+\.]+)/([\d+\.]+)/([\d+\.]+) ms})
      result[:min]    = m[2].to_f
      result[:avg]    = m[3].to_f
      result[:max]    = m[4].to_f
      result[:stddev] = m[5].to_f
    end

    result
  end

  def default_gateway
    route = %x{/bin/netstat -rn}
    route[/^(0\.0\.0\.0|default)\s+(\d+\.\d+\.\d+\.\d+)\s+/, 2]
  end
end
