module RSpec
  module Mocks
    # Used to encapsulate and verify mocks as well as reset mocks
    class Space
      # Adds an object to the mock array if it previously did not exist
      def add(obj)
        mocks << obj unless mocks.detect {|m| m.equal? obj}
      end

      # calls rspec_verify on each object in the mocks array
      # @see RSpec::Mocks::Methods#rspec_verify
      def verify_all
        mocks.each do |mock|
          mock.rspec_verify
        end
      end

      # calls rspec_reset on each object in the mocks array
      # then removes all elements from the mocks array
      # @see RSpec::Mocks::Methods#rspec_reset
      def reset_all
        mocks.each do |mock|
          mock.rspec_reset
        end
        mocks.clear
      end

    private
      # holds all mock objects
      def mocks
        @mocks ||= []
      end
    end
  end
end
