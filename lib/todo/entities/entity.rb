class Todo
  module Entities
    class Entity
      def initialize(record)
        @record = record
      end

      attr_reader :record

      def method_missing(method, args = nil)
        super unless record.key? method

        return unless record.key? method

        @record[method]
      end

      def to_json(*_args)
        @record.to_json
      end
    end
  end
end
require_relative '../entities'
