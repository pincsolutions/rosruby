#!/usr/bin/env ruby

require 'ros'
require 'test/unit'

class TestNode < Test::Unit::TestCase
  def test_up_down
    node1 = ROS::Node.new('/test_up_down')
    assert_equal('/test_up_down', node1.node_name)
    assert(node1.ok?)
    node1.shutdown
    assert(!node1.ok?)
    node2 = ROS::Node.new('/test2')
    assert(node2.ok?)
    node2.shutdown
    assert(!node2.ok?)
  end

  def test_multi_up_down
    node1 = ROS::Node.new('/test_multi_1')
    node2 = ROS::Node.new('/test_multi_2')
    assert(node1.ok?)
    assert(node2.ok?)
    node1.shutdown
    node2.shutdown
    assert(!node1.ok?)
    assert(!node2.ok?)
  end

  def test_anonymous
    node1 = ROS::Node.new('/test_anonymous1', :anonymous=>true)
    assert_not_equal('/test_anonymous1', node1.node_name)
    node2 = ROS::Node.new('/test_anonymous1', :anonymous=>true)
    assert_not_equal('/test_anonymous1', node2.node_name)
    sleep(0.5)
    assert(node1.ok?)
    assert(node2.ok?)
    node1.shutdown
    node2.shutdown
    assert(!node1.ok?)
    assert(!node2.ok?)
  end

  def test_not_anonymous
    node1 = ROS::Node.new('/test_not_anonymous1')
    node2 = ROS::Node.new('/test_not_anonymous1')
    sleep(0.5)
    assert(!node1.ok?) # killed by master
    assert(node2.ok?)
    node1.shutdown
    node2.shutdown
    assert(!node2.ok?)
  end

  def test_signal
    node1 = ROS::Node.new('/test_signal1')
    Process.kill("INT", Process.pid)
    sleep(0.5)
    assert(!node1.ok?)
  end

  def test_master_uri
    node1 = ROS::Node.new('/test_master_uri1')
    assert_equal(node1.master_uri, ENV['ROS_MASTER_URI'])

    node1.shutdown
  end

  def test_ros_env
    # check ROS_IP
    ENV['ROS_IP']='127.0.0.1'
    node1 = ROS::Node.new('/test_ros_env')
    assert_equal('127.0.0.1', node1.host)
    node1.shutdown
    ENV.delete('ROS_IP')

    # check ROS_HOSTNAME
    ENV['ROS_HOSTNAME']='localhost'
    node2 = ROS::Node.new('/test_ros_env2')
    assert_equal('localhost', node2.host)
    node2.shutdown

    ENV['ROS_HOSTNAME']='127.0.0.1'
    node2 = ROS::Node.new('/test_ros_env2')
    assert_equal('127.0.0.1', node2.host)
    node2.shutdown
    ENV.delete('ROS_HOSTNAME')
  end

  def test_param_set_get
    node = ROS::Node.new('hoge')
    # integer
    assert(node.set_param('/test1', 1))
    assert_equal(1, node.get_param('/test1'))
    # float
    assert(node.set_param('/test_f', 0.1))
    assert_equal(0.1, node.get_param('/test_f'))
    assert(node.delete_param('/test_f'))
    # list
    assert(node.set_param('/test2', [1,2,3]))
    assert_equal([1,2,3], node.get_param('/test2'))
    # string
    assert(node.set_param('/test_s', 'hoge'))
    assert_equal('hoge', node.get_param('/test_s'))

    # default param
    assert_equal('hoge', node.get_param('/test_xxxx', 'hoge'))

    # delete not exist
    assert(!node.delete_param('/xxxxx'))

    assert(node.has_param('/test_s'))
    assert(node.delete_param('/test_s'))
    assert(!node.has_param('/test_s'))

    node.shutdown
  end

  def test_param_private
    node = ROS::Node.new('/hoge')
    node.set_param('/hoge/param1', 100)
    assert_equal(100, node.get_param('~param1'))

    node.set_param('~param2', 10)
    assert_equal(10, node.get_param('/hoge/param2'))
    assert(node.delete_param('~param2'))
    node.shutdown
  end

  def test_fail
    node = ROS::Node.new('hoge')
    assert(!node.get_param('/test_no_exists'))
    node.shutdown
  end

  def test_resolve_name
    node = ROS::Node.new('hoge')

    assert_equal('/aaa', node.resolve_name('aaa'))
    assert_equal('/aaa/b/c', node.resolve_name('aaa/b////c'))
    assert_equal('/hoge/private', node.resolve_name('~private'))
    node.shutdown
  end

  def test_param_subscribe
    node = ROS::Node.new('/test_param_sub')
    called = false
    subscriber = node.subscribe_parameter('/test_param1') do |param|
      called = param
    end
    node.set_param('/test_param1', 1)
    sleep(0.5)
    assert_equal(1, called)
    node.set_param('/test_param1', 2)
    subscriber.shutdown
    sleep(0.5)
    assert_equal(1, called)
    node.shutdown
  end
end
