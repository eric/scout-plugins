require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('../mysql_mmm', __FILE__)

class MysqlMmmTest < Test::Unit::TestCase
  EXAMPLE_RESULT = <<-EOF
  pt01d01(10.12.48.194) master/ONLINE. Roles: 
  pt01d02(10.12.48.200) master/ONLINE. Roles: writer(10.12.86.65)

  EOF

  def setup
    @plugin = MysqlMmm.new(nil, {}, {})
  end

  def test_parse_states
    result = @plugin.parse_mmm_control_show(EXAMPLE_RESULT)

    assert_equal 2, result['master/ONLINE']
    assert_equal 1, result.length
  end

  def test_plugin
    IO.stubs(:popen).with('sudo mmm_control show').returns(EXAMPLE_RESULT)
    result = @plugin.run

    assert_equal([{ 'master/ONLINE' => 2 }], result[:reports])
  end
end