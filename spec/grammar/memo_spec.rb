require 'spec_helper'
require 'set'

describe Calyx::Grammar do
  describe 'memoized rules' do
    specify 'memoized rule mapped with symbol prefix' do
      grammar = Calyx::Grammar.new do
        rule :start, '{@tramp}:{@tramp}'
        rule :tramp, :@character
        rule :character, 'Vladimir', 'Estragon'
      end

      actual = grammar.generate.split(':')
      expect(actual.first).to eq(actual.last)
    end

    specify 'memoized rule mapped with template expression' do
      grammar = Calyx::Grammar.new do
        rule :start, :pupper
        rule :pupper, '{@spitz}:{@spitz}'
        rule :spitz, 'pomeranian', 'samoyed', 'shiba inu'
      end

      actual = grammar.generate.split(':')
      expect(actual.first).to eq(actual.last)
    end

    specify 'memoized rules are reset between multiple runs' do
      grammar = Calyx::Grammar.new do
        rule :start, '{flower}{flower}{flower}'
        rule :flower, :@flowers
        rule :flowers, '🌷', '🌻', '🌼'
      end

      generations = Set.new

      while generations.size < 3
        generation = grammar.generate
        expect(generation).to match(/🌷🌷🌷|🌻🌻🌻|🌼🌼🌼/)
        generations << generation
      end
    end

    specify 'memoized rules capture nested expansions' do
      grammar = Calyx::Grammar.new do
        rule :start, '{@chain}:{@chain}'
        rule :chain, '{one}{one}', '{two}{two}', '{three}{three}'
        rule :one, '{a}'
        rule :two, '{b}'
        rule :three, '{c}'
        rule :a, 'a', 'A'
        rule :b, 'b', 'B'
        rule :c, 'c', 'C'
      end

      actual = grammar.generate.split(':')
      expect(actual.first).to eq(actual.last)
    end
  end
end
