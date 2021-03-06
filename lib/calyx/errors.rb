module Calyx
  # Library-specific error types.
  module Errors
    # Only rules that exist in the registry can be evaluated. When a
    # non-existent rule is referenced, this error is raised.
    #
    #   grammar = Calyx::Grammar.new do
    #     start :blank
    #   end
    #
    #   grammar.evaluate
    #   # => Calyx::Errors::UndefinedRule: :blank is not defined
    class UndefinedRule < RuntimeError
      def initialize(rule, symbol)
        @trace = if rule
          rule.trace
        else
          trace_api_boundary(caller_locations)
        end

        super("undefined rule :#{symbol} in #{@trace.path}:#{@trace.lineno}:`#{source_line}`")
      end

      def trace_api_boundary(trace)
        (trace.count - 1).downto(0) do |index|
          if trace[index].to_s.include?('lib/calyx/')
            return trace[index + 1]
          end
        end
      end

      def source_line
        File.open(@trace.absolute_path) do |source|
          (@trace.lineno-1).times { source.gets }
          source.gets
        end.strip
      end
    end

    # Raised when a rule passed in via a context map conflicts with an existing
    # rule in the grammar.
    #
    #   grammar = Calyx::Grammar.new do
    #     start :priority
    #     priority "(A)"
    #   end
    #
    #   grammar.evaluate(priority: "(B)")
    #   # => Calyx::Errors::DuplicateRule: :priority is already registered
    class DuplicateRule < ArgumentError
      def initialize(msg)
        super(":#{msg} is already registered")
      end
    end

    # Raised when the client attempts to load a grammar with an unsupported file
    # extension. Only `.json` and `.yml` are valid.
    #
    #   Calyx::Grammar.load("grammar.toml")
    #   # => Calyx::Errors::UnsupportedFormat: grammar.toml is not a valid JSON or YAML file
    class UnsupportedFormat < ArgumentError
      def initialize(msg)
        super("#{File.basename(msg)} is not a valid JSON or YAML file")
      end
    end

    # Raised when a rule defined in a grammar is invalid. This will prevent
    # the grammar from compiling correctly.
    #
    #   Calyx::Grammar.new do
    #     start '40%' => 0.4, '30%' => 0.3
    #   end
    #
    #   # => Calyx::Errors::InvalidDefinition: Weights must sum to 1
    #
    class InvalidDefinition < ArgumentError
    end
  end
end
