require 'sentinel/adapter/csv_adapter'
require 'sentinel/events'
require 'uri'

module Sentinel
  class AbstractAdapter

    @@outputs = []
    @@path = nil


    # Returns formats defined on config/output.yml.
    #
    # @return [Array] An array containing the outputs defined on the file.
    # Default is ['CSV'].
    def self.formats
      @@outputs = YAML.load_file('config/output.yml')['outputs'] if (@@outputs.nil? || @@outputs.empty?)

      (@@outputs.nil? || @@outputs.empty?) ? ['CSV'] : @@outputs
      @@outputs.map{ |output| eval "#{output}Adapter" }
    end

    # Returns the path where to save the ouput files.
    #
    # @return [String] A string with the path where to save output files.
    # Default is logs/.
    def self.output_dir
      @@path = YAML.load_file('config/output.yml')['directory_path'] if (@@path.nil? || @@path.empty?)

      (@@path.nil? || @@path.empty?) ? 'logs/' : @@path
    end

    # Saves the event on the log file.
    # @param [Object, String] The event received from the IRC channel and a
    # string containing the type of the event.
    # @return [void]
    def self.save_event(event, type)
      case type
      when Sentinel::Events::MESSAGE
        self.save_message(event)
      when Sentinel::Events::PRIVATE
        self.save_private_messages(event)
      when Sentinel::Events::JOIN
        self.save_join(event)
      when Sentinel::Events::LEAVING
        self.save_leaving(event)
      when Sentinel::Events::TOPIC
        self.save_topic(event)
      else
        self.save_message(event)
      end
    end

    protected

    def self.save_message(event)
      self.formats.each do |adapter|
        adapter.save_message(event)
      end
    end

    def self.save_private_messages(event)
      self.formats.each do |adapter|
        adapter.save_private_messages(event)
      end
    end

    def self.save_join(event)
      self.formats.each do |adapter|
        adapter.save_join(event)
      end
    end

    def self.save_leaving(event)
      self.formats.each do |adapter|
        adapter.save_leaving(event)
      end
    end

    def self.save_message_with_keyword(message)
      self.formats.each do |adapter|
        adapter.save_message_with_keyword(message)
      end
    end

    # Extracts URLs from the content of IRC messages.
    #
    # @param [Message] The IRC message captured
    # @return [String] A String with all URLs within the message content, separated by commas.
    def self.extract_urls(message)
      return URI.extract(message.message, ['http', 'https', 'ftp']).to_s.gsub(/(\")|(\[)|(\])/, '')
    end

    # Extracts the channel name from which a message has been sent,if it exists.
    # If it doesn't, it returns "PRIVATE_MSG"
    #
    # @param [Message] The IRC message captured
    # @return [String] A String with the channel name or the string "PRIVATE_MSG".
    def self.channel_name(message)
      message.channel.nil? ? "PRIVATE_MSG" : message.channel.name
    end
  end
end
