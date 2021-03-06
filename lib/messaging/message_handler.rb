require 'json'
require 'time'
require_relative 'mesh_message'
require_relative '../command_objects/build_mesh_message'
require_relative '../command_objects/resolve_controller'

module FBPi
  # Get the JSON command, received through skynet, and send it to the farmbot
  # command queue Parses JSON messages received through SkyNet.
  class MessageHandler
    attr_accessor :message, :bot, :mesh

    ## general handling messages
    def initialize(message_hash, bot, mesh)
      @bot, @mesh, @message = bot, mesh, BuildMeshMessage.run!(message_hash)
    end

    def call
      controller_klass = ResolveController.run!(method: message.method)
      controller_klass.new(message, bot, mesh).call
    rescue Exception => e
      send_error(e)
    end

    # Make a new instance and call() it.
    def self.call(message, bot, mesh)
      self.new(message, bot, mesh).call
    end

    def send_error(error)
      msg = "#{error.message} @ #{error.backtrace.first}"
      bot.log msg
      reply 'error', message: error.message, backtrace: error.backtrace
    end

    def reply(method, reslt = {})
      SendMeshResponse.run!(original_message: message,
                            mesh:             mesh,
                            method:           method,
                            result:           reslt)
    end

  end
end
