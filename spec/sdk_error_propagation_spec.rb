require 'spec_helper'

RSpec.describe 'SDK errors propagate through the Liquid layer' do
  let(:finalized_error) { IllegalStateException.new('ABsmartly Context is finalized.') }
  let(:ctx) do
    double('context', ready?: true).tap do |c|
      %i[treatment peek_treatment variable_value peek_variable_value custom_field_value experiments track]
        .each { |m| allow(c).to receive(m).and_raise(finalized_error) }
    end
  end
  let(:drop) { ABsmartly::Liquid::Drop.new(ctx) }

  def render(source, assigns = {})
    Liquid::Template.parse(source).render!(assigns.merge('absmartly' => drop))
  end

  before { ABsmartly::Liquid.strict_mode = false }

  describe 'reads on a finalized context (non-strict mode)' do
    it 'Drop methods raise the finalized error' do
      expect { drop.treatment('exp') }.to raise_error(IllegalStateException, finalized_error.message)
      expect { drop.peek('exp') }.to raise_error(IllegalStateException, finalized_error.message)
      expect { drop.variable('k', 'd') }.to raise_error(IllegalStateException, finalized_error.message)
      expect { drop.peek_variable('k', 'd') }.to raise_error(IllegalStateException, finalized_error.message)
      expect { drop.custom_field('exp', 'f') }.to raise_error(IllegalStateException, finalized_error.message)
    end

    it 'the treatment tag raises instead of rendering control' do
      expect { render("{% absmartly_treatment 'exp' %}{{ variant }}{% endabsmartly_treatment %}") }
        .to raise_error(IllegalStateException, finalized_error.message)
    end

    it 'filters raise instead of returning defaults' do
      expect { render("{{ 'exp' | absmartly_treatment }}") }.to raise_error(IllegalStateException)
      expect { render("{{ 'exp' | absmartly_peek }}") }.to raise_error(IllegalStateException)
      expect { render("{{ 'k' | absmartly_variable: 'd' }}") }.to raise_error(IllegalStateException)
      expect { render("{{ 'k' | absmartly_peek_variable: 'd' }}") }.to raise_error(IllegalStateException)
      expect { render("{{ 'exp' | absmartly_custom_field: 'f' }}") }.to raise_error(IllegalStateException)
    end
  end

  describe 'experiments' do
    it 'raises the SDK error instead of returning []' do
      allow(ctx).to receive(:experiments)
        .and_raise(IllegalStateException.new('ABsmartly Context is not yet ready.'))
      expect { drop.experiments }.to raise_error(IllegalStateException, /not yet ready/)
    end
  end

  describe 'track' do
    it 'Drop#track raises the finalized error' do
      expect { drop.track('goal', {}) }.to raise_error(IllegalStateException, finalized_error.message)
    end

    it 'the track tag raises the finalized error' do
      expect { render("{% absmartly_track 'goal' %}") }.to raise_error(IllegalStateException)
    end

    it 'the track filter raises the finalized error' do
      expect { render("{{ 'goal' | absmartly_track }}") }.to raise_error(IllegalStateException)
    end

    it 'passes invalid goal properties to the SDK and raises its error' do
      error = ArgumentError.new("Goal 'goal' properties must be of type object.")
      allow(ctx).to receive(:track).with('goal', 125).and_raise(error)
      expect { drop.track('goal', 125) }.to raise_error(ArgumentError, error.message)
    end
  end
end
