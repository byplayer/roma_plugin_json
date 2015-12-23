require 'roma/messaging/con_pool'
require 'roma/command/command_definition'
require 'json'

module Roma
  module CommandPlugin
    # ROMA plugin
    module PluginJson
      include Roma::CommandPlugin
      include Roma::Command::Definition

      # json_set <key> <json_key> <flags> <expt> <bytes> [forward]\r\n
      # <data block>\r\n
      #
      # (STORED|NOT_STORED|SERVER_ERROR <error message>)\r\n
      def_write_command_with_key_value :json_set, 5 do |ctx|
        v = {}
        v = JSON.parse(ctx.stored.value) if ctx.stored
        v[ctx.argv[2]] = ctx.params.value
        expt = chg_time_expt(ctx.argv[4].to_i)

        # [flags, expire time, value, kind of counter(:write/:delete), result message]
        [0, expt, v.to_json, :write, 'STORED']
      end

      # json_get <key> <json_key> [forward]\r\n
      #
      # (
      # [VALUE <key> 0 <value length>\r\n
      # <value>\r\n]
      # END\r\n
      # |SERVER_ERROR <error message>\r\n)
      def_read_command_with_key :json_get, :multi_line do |ctx|
        if ctx.stored
          v = JSON.parse(ctx.stored.value)[ctx.argv[2]]
          send_data("VALUE #{ctx.params.key} 0 #{v.length}\r\n#{v}\r\n") if v
        end
        send_data("END\r\n")
      end
    end
  end
end
