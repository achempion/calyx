module Calyx
  # The main public interface to Calyx. Grammars represent the concept of a
  # template grammar defined by a set of production rules that can be chained
  # and nested from a given starting rule.
  #
  # Calyx works like a traditional phrase-structured grammar in reverse. Instead
  # of recognising strings based on a union of possible matches, it generates
  # strings by representing the union as a choice and randomly picking one
  # of the options each time the grammar runs.
  class Grammar
    class << self
      # Access the registry belonging to this grammar class.
      #
      # Constructs a new registry if it isn't already available.
      #
      # @return [Calyx::Registry]
      def registry
        @registry ||= Registry.new
      end

      # Load a grammar instance from the given file.
      #
      # Accepts a JSON or YAML file path, identified by its extension (`.json`
      # or `.yml`).
      #
      # @param [String] filename
      # @return [Calyx::Grammar]
      def load(filename)
        Format.load(filename)
      end

      # DSL helper method for registering a modifier module with the grammar.
      #
      # @param [Module] module_name
      def modifier(module_name)
        warn [
          "NOTE: Loading modifiers via grammar class methods is deprecated.",
          "Alternative API TBD. For now this method still works."
        ].join
        registry.modifier(module_name)
      end

      # DSL helper method for registering a paired mapping regex.
      #
      # @param [Symbol] name
      # @param [Hash<Regex,String>] pairs
      def mapping(name, pairs)
        warn [
          "NOTE: The fixed `mapping` class method is deprecated.",
          "This still works but will be replaced with a new mapping format."
        ].join
        registry.mapping(name, pairs)
      end

      # DSL helper method for registering the given block as a string filter.
      #
      # @param [Symbol] name
      # @yieldparam [String] the input string to be processed by the filter
      # @yieldreturn [String] the processed output string
      def filter(name, &block)
        warn [
          "NOTE: The fixed `filter` class method is deprecated.",
          "This will be removed in 0.22. Use the API for modifers instead."
        ].join
        registry.filter(name, &block)
      end

      # DSL helper method for registering a new grammar rule.
      #
      # Not usually used directly, as the method missing API is less verbose.
      #
      # @param [Symbol] name
      # @param [Array] productions
      def rule(name, *productions)
        registry.define_rule(name, caller_locations.first, productions)
      end

      # Augument the grammar with a method missing hook that treats class
      # method calls as declarations of a new rule.
      #
      # This must be bypassed by calling `#rule` directly if the name of the
      # desired rule clashes with an existing helper method.
      #
      # @param [Symbol] name
      # @param [Array] productions
      def method_missing(name, *productions)
        registry.define_rule(name, caller_locations.first, productions)
      end

      # Hook for combining the registry of a parent grammar into the child that
      # inherits from it.
      #
      # @param [Calyx::Registry] child_registry
      def inherit_registry(child_registry)
        registry.combine(child_registry) unless child_registry.nil?
      end

      # Hook for combining the rules from a parent grammar into the child that
      # inherits from it.
      #
      # This is automatically called by the Ruby engine.
      #
      # @param [Class] subclass
      def inherited(subclass)
        subclass.inherit_registry(registry)
      end
    end

    # Create a new grammar instance, passing in a random seed if needed.
    #
    # Grammar rules can be constructed on the fly when the passed-in block is
    # evaluated.
    #
    # @param [Numeric, Random, Hash] options
    def initialize(options={}, &block)
      unless options.is_a?(Hash)
        config_opts = {}
        if options.is_a?(Numeric)
          warn [
            "NOTE: Passing a numeric seed arg directly is deprecated. ",
            "Use the options hash instead: `Calyx::Grammar.new(seed: 1234)`"
          ].join
          config_opts[:seed] = options
        elsif options.is_a?(Random)
          warn [
            "NOTE: Passing a Random object directly is deprecated. ",
            "Use the options hash instead: `Calyx::Grammar.new(rng: Random.new)`"
          ].join
          config_opts[:rng] = options
        end
      else
        config_opts = options
      end

      @options = Options.new(config_opts)

      if block_given?
        @registry = Registry.new
        @registry.instance_eval(&block)
      else
        @registry = self.class.registry
      end

      @registry.options(@options)
    end

    # Produces a string as an output of the grammar.
    #
    # @overload generate(start_symbol)
    #   @param [Symbol] start_symbol
    # @overload generate(rules_map)
    #   @param [Hash] rules_map
    # @overload generate(start_symbol, rules_map)
    #   @param [Symbol] start_symbol
    #   @param [Hash] rules_map
    # @return [String]
    def generate(*args)
      result = generate_result(*args)
      result.text
    end

    # Produces a syntax tree of nested list nodes as an output of the grammar.
    #
    # @deprecated Please use {#generate_result} instead.
    def evaluate(*args)
      warn <<~DEPRECATION
        [DEPRECATION] `evaluate` is deprecated and will be removed in 1.0.
        Please use #generate_result instead.
        See https://github.com/maetl/calyx/issues/23 for more details.
      DEPRECATION

      result = generate_result(*args)
      result.tree
    end

    # Produces a generated result from evaluating the grammar.
    #
    # @see Calyx::Result
    # @overload generate_result(start_symbol)
    #   @param [Symbol] start_symbol
    # @overload generate_result(rules_map)
    #   @param [Hash] rules_map
    # @overload generate_result(start_symbol, rules_map)
    #   @param [Symbol] start_symbol
    #   @param [Hash] rules_map
    # @return [Calyx::Result]
    def generate_result(*args)
      start_symbol, rules_map = map_default_args(*args)

      Result.new(@registry.evaluate(start_symbol, rules_map))
    end

    private

    def map_default_args(*args)
      start_symbol = :start
      rules_map = {}

      args.each do |arg|
        start_symbol = arg if arg.class == Symbol
        rules_map = arg if arg.class == Hash
      end

      [start_symbol, rules_map]
    end
  end
end
