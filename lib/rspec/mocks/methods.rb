module RSpec
  module Mocks
    # These methods are included in Object, so anything inheriting from Object (i.e. everything) will have these instance methods. Of note are methods allowing expectations
    # to be set Methods#should_receive and Method#should_not_receive, as well as methods allowing methods to be stubbed out Methods#stub
    module Methods

      # should_receive sets an expectation on the caller that will cause the
      # spec to fail if the expectaion is not satisfied
      #
      # @example
      #   foo = String.new("1,2,3,4")
      #   foo.should_receive(:split)
      #   foo.split(",")
      #   # spec will PASS, since :split was received
      #
      #   foo = String.new("1,2,3,4")
      #   foo.should_receive(:split)
      #   foo.gsub("," , "|")
      #   # spec will FAIL, since :split was not received
      def should_receive(sym, opts={}, &block)
        __mock_proxy.add_message_expectation(opts[:expected_from] || caller(1)[0], sym.to_sym, opts, &block)
      end


      # should_receive is the negation of should_receive
      # it sets an expectation on the caller that will cause the
      # spec to fail if the expectaion is satisfied
      #
      # @example
      #   foo = String.new("1,2,3,4")
      #   foo.should_not_receive(:split)
      #   foo.split(",")
      #   # spec will FAIL, since :split was received
      #
      #   foo = String.new("1,2,3,4")
      #   foo.should_not_receive(:split)
      #   foo.gsub("," , "|")
      #   # spec will PASS, since :split was not received
      #
      def should_not_receive(sym, &block)
        __mock_proxy.add_negative_message_expectation(caller(1)[0], sym.to_sym, &block)
      end

      # stub will replace the method specified on the caller, unlike
      # should_receive, stub does not set an expectation on the caller
      # so whether or not the method is called the test will pass
      #
      # @example
      #   bar = [1,2,3,4]
      #   bar.to_s # => "1234"
      #   bar.stub(:to_s)
      #   bar.to_s # => nil
      #
      # Optionally a return value can be specified while declaring the
      # stub by passing in a hash
      #
      # @example
      #   bar = [1,2,3,4]
      #   bar.to_s # => "1234"
      #   bar.stub(:to_s => "not what you were expecting")
      #   bar.to_s # => "not what you were expecting"
      def stub(sym_or_hash, opts={}, &block)
        if Hash === sym_or_hash
          sym_or_hash.each {|method, value| stub(method).and_return value }
        else
          __mock_proxy.add_stub(caller(1)[0], sym_or_hash.to_sym, opts, &block)
        end
      end

      # removes the stub from the object
      #
      # @example
      #   bahz = 42
      #   bahz.even? # => true
      #   bahz.stub(:even? => "nope")
      #   bahz.even? # => "nope"
      #
      #   bahz.unstub(:even?)
      #   bhaz.even? # => true
      def unstub(sym)
        __mock_proxy.remove_stub(sym)
      end

      alias_method :stub!, :stub
      alias_method :unstub!, :unstub

      # Stubs multiple methods called in sequence on an object.
      # It can be used in combination a hash or with and_return to specify a return value
      #
      # @example
      #   Article.where(:published => true).order(:created_at).limit(10).first
      #   # => [<# Article ...>, <# Article ...>, <# Article ...>, ... ]
      #
      #   Article.stub_chain(:published, :order, :limit, :first).and_return("whatever we want")
      #   Article.where(:published => true).order(:created_at).limit(10).first
      #   # => "whatever we want"
      #
      #   Article.stub_chain(:published, :order, :limit, :first => "whatever we want")
      #   Article.where(:published => true).order(:created_at).limit(10).first
      #   # => "whatever we want"
      #
      #
      #
      #   Article.stub_chain("published,order,fimit,first").and_return("whatever we want")
      #   Article.where(:published => true).order(:created_at).limit(10).first
      #   # => "whatever we want"
      #
      def stub_chain(*chain, &blk)
        chain, blk = format_chain(*chain, &blk)
        if chain.length > 1
          if matching_stub = __mock_proxy.__send__(:find_matching_method_stub, chain[0].to_sym)
            chain.shift
            matching_stub.invoke.stub_chain(*chain, &blk)
          else
            next_in_chain = Object.new
            stub(chain.shift) { next_in_chain }
            next_in_chain.stub_chain(*chain, &blk)
          end
        else
          stub(chain.shift, &blk)
        end
      end

      # will return true if the caller (a double) has received the symbol as a method, otherwise false
      # @see RSpec::Mocks::Proxy#received_message?
      def received_message?(sym, *args, &block) #:nodoc:
        __mock_proxy.received_message?(sym.to_sym, *args, &block)
      end

      # @see RSpec::Mocks::Proxy#verify
      def rspec_verify #:nodoc:
        __mock_proxy.verify
      end

      # @see RSpec::Mocks::Proxy#reset
      def rspec_reset #:nodoc:
        __mock_proxy.reset
      end

      # @see RSpec::Mocks::Proxy#as_null_object
      def as_null_object
        __mock_proxy.as_null_object
      end

      # @see RSpec::Mocks::Proxy#null_object?
      def null_object?
        __mock_proxy.null_object?
      end

    private

      def __mock_proxy
        @mock_proxy ||= begin
          mp = if Mock === self
            Proxy.new(self, @name, @options)
          else
            Proxy.new(self)
          end

          Serialization.fix_for(self)
          mp
        end
      end

      def format_chain(*chain, &blk)
        if Hash === chain.last
          hash = chain.pop
          hash.each do |k,v|
            chain << k
            blk = lambda { v }
          end
        end
        return chain.join('.').split('.'), blk
      end
    end
  end
end
