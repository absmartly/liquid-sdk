require 'spec_helper'
require 'liquid'
require 'ostruct'

RSpec.describe ABsmartly::Liquid::Filters do
  let(:experiment_data) do
    {
      'experiments' => [
        {
          'id' => 1,
          'name' => 'exp_test',
          'unitType' => 'session_id',
          'iteration' => 1,
          'seedHi' => 0,
          'seedLo' => 1,
          'split' => [0.5, 0.5],
          'trafficSeedHi' => 0,
          'trafficSeedLo' => 0,
          'trafficSplit' => [1.0, 0.0],
          'fullOnVariant' => 0,
          'applications' => [{ 'name' => 'test' }],
          'variants' => [
            { 'name' => 'control', 'config' => '{"button_color":"blue"}' },
            { 'name' => 'treatment', 'config' => '{"button_color":"red"}' }
          ],
          'audience' => '',
          'audienceStrict' => false
        }
      ]
    }
  end

  let(:event_collector) { TestEventCollector.new }

  let(:context) do
    create_test_context(
      units: { session_id: 'test123' },
      data: experiment_data,
      event_collector: event_collector
    )
  end

  let(:drop) { ABsmartly::Liquid::Drop.new(context) }

  describe '#absmartly_treatment' do
    it 'returns treatment variant' do
      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_treatment }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('0')
    end

    it 'tracks exposure' do
      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_treatment }}")
      template.render('absmartly' => drop)

      expect(context.pending_count).to be >= 1
    end

    it 'returns 0 when context not ready' do
      ctx = double('context', ready?: false)
      allow(ctx).to receive(:treatment).and_return(0)
      drop = ABsmartly::Liquid::Drop.new(ctx)

      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_treatment }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('0')
    end
  end

  describe '#absmartly_peek' do
    it 'returns treatment variant without tracking' do
      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_peek }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('0')
    end

    it 'does not track exposure' do
      initial_pending = context.pending_count

      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_peek }}")
      template.render('absmartly' => drop)

      expect(context.pending_count).to eq(initial_pending)
    end
  end

  describe '#absmartly_variable' do
    it 'returns variable value' do
      template = Liquid::Template.parse("{{ 'button_color' | absmartly_variable: 'default' }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('blue')
    end

    it 'returns default when variable not found' do
      template = Liquid::Template.parse("{{ 'unknown_var' | absmartly_variable: 'default' }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('default')
    end
  end

  describe '#absmartly_peek_variable' do
    it 'returns variable value without tracking' do
      initial_pending = context.pending_count

      template = Liquid::Template.parse("{{ 'button_color' | absmartly_peek_variable: 'default' }}")
      output = template.render('absmartly' => drop)

      expect(context.pending_count).to eq(initial_pending)
      expect(output).to eq('blue')
    end
  end

  describe '#absmartly_track' do
    it 'tracks goal' do
      initial_pending = context.pending_count

      template = Liquid::Template.parse("{{ 'purchase' | absmartly_track: amount: 99.99 }}")
      template.render('absmartly' => drop)

      expect(context.pending_count).to be > initial_pending
    end

    it 'returns empty string' do
      template = Liquid::Template.parse("{{ 'purchase' | absmartly_track: amount: 99.99 }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('')
    end
  end
end
