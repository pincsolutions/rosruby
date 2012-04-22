# ros/tcpros/service_server.rb
#
# License: BSD
#
# Copyright (C) 2012  Takashi Ogura <t.ogura@gmail.com>
#
require 'ros/tcpros/message'
require 'gserver'

module ROS::TCPROS

  ##
  # TCPROS protocol Service Server
  #
  class ServiceServer < ::GServer

    ##
    # max number of connection with clients
    #
    MAX_CONNECTION = 100

    include ::ROS::TCPROS::Message

    def initialize(caller_id, service_name, service_type, callback,
                   port=0, host=::GServer::DEFAULT_HOST)
      super(port, host, MAX_CONNECTION)
      @caller_id = caller_id
      @service_name = service_name
      @service_type = service_type
      @callback = callback
      @byte_received = 0
      @byte_sent = 0
    end

    ##
    # message must send 1 byte for service call result (true)
    #
    def send_ok_byte(socket)
      socket.write([1].pack('c'))
    end

    ##
    # message must send 1 byte for service call result (false)
    #
    def send_ng_byte(socket)
      socket.write([0].pack('c'))
    end

    def read_and_callback(socket)
      request = @service_type.request_class.new
      response = @service_type.response_class.new
      data = read_all(socket)
      @byte_received += data.length
      request.deserialize(data)
      result = @callback.call(request, response)
      if result
        send_ok_byte(socket)
        data = write_msg(socket, response)
        @byte_sent += data.length
      else
        send_ng_byte(socket)
        write_header(socket, build_header)
        # write some message
      end
      result
    end

    ##
    # this is called by socket accept
    #
    def serve(socket)
      header = read_header(socket)
      # not documented protocol?
      if header['probe'] == '1'
        write_header(socket, build_header)
      elsif check_header(header)
        write_header(socket, build_header)
        read_and_callback(socket)
        if header['persistent'] == '1'
          loop do
            read_and_callback(socket)
          end
        end
      else
        socket.close
        raise 'header check error'
      end
    end

    ##
    # check header
    def check_header(header)
      header.valid?('md5sum', @service_type.md5sum)
    end

    ##
    # build header message for service server
    # @return ROS::TCPROS::Header
    def build_header
      header = Header.new
      header["callerid"] = @caller_id
      header['type'] = @service_type.type
      header['md5sum'] = @service_type.md5sum
      header
    end

    # received data amout for slave api
    attr_reader :byte_received

    # sent data amout for slave api
    attr_reader :byte_sent

  end
end