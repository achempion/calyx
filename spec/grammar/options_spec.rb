describe Calyx::Grammar do
  describe 'options' do
    class Metallurgy < Calyx::Grammar
      start "platinum", "titanium", "tungsten"
    end

    describe ':seed' do
      it 'accepts a seed in the legacy constructor format' do
        grammar = Metallurgy.new(43210)

        expect(grammar.generate).to eq("platinum")
      end

      it 'accepts a seed option' do
        grammar = Metallurgy.new(seed: 43210)

        expect(grammar.generate).to eq("platinum")
      end
    end

    describe ':rng' do
      it 'accepts a random instance in the legacy constructor format' do
        grammar = Metallurgy.new(Random.new(43210))

        expect(grammar.generate).to eq("platinum")
      end

      it 'accepts a random instance as an option' do
        grammar = Metallurgy.new(rng: Random.new(43210))

        expect(grammar.generate).to eq("platinum")
      end
    end
  end
end
