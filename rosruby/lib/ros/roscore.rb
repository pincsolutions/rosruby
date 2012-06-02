#!/usr/bin/env ruby

require 'ros/master'
require 'ros'

module ROS

  def self.start_roscore
    # master
    thread = Thread.new do 
      ROS::Master.new.start
    end
    
    sleep 1
    
    # rosout
    rosout_node = ROS::Node.new('/rosout', :nologger=>true)
    rosout_agg_publisher = rosout_node.advertise('/rosout_agg', Rosgraph_msgs::Log)
    rosout_node.subscribe('/rosout', Rosgraph_msgs::Log) do |msg|
      rosout_agg_publisher.publish(msg)
    end
    rosout_node.spin
  end
end

if $0 == __FILE__
  ROS::start_roscore
end

