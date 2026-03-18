require 'spec_helper'
require 'liquid'
require 'logger'
require 'stringio'

RSpec.describe 'Fix plan validations' do
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

  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  before do
    @original_logger = ABsmartly::Liquid.logger
    @original_strict = ABsmartly::Liquid.strict_mode
    ABsmartly::Liquid.logger = logger
    ABsmartly::Liquid.strict_mode = false
  end

  after do
    ABsmartly::Liquid.logger = @original_logger
    ABsmartly::Liquid.strict_mode = @original_strict
  end

  describe 'Fix #1: current_context accessor' do
    it 'exposes current_context accessor' do
      expect(ABsmartly::Liquid).to respond_to(:current_context)
      expect(ABsmartly::Liquid).to respond_to(:current_context=)
    end
  end

  describe 'Fix #2: absmartly_track uses with_ready_context' do
    it 'returns empty string when context missing' do
      template = Liquid::Template.parse("{{ 'purchase' | absmartly_track }}")
      output = template.render({})
      expect(output).to eq('')
    end

    it 'returns empty string when context not ready' do
      not_ready_ctx = double('context', ready?: false)
      not_ready_drop = ABsmartly::Liquid::Drop.new(not_ready_ctx)

      template = Liquid::Template.parse("{{ 'purchase' | absmartly_track }}")
      output = template.render('absmartly' => not_ready_drop)
      expect(output).to eq('')
    end

    it 'tracks successfully when context is ready' do
      template = Liquid::Template.parse("{{ 'purchase' | absmartly_track }}")
      output = template.render('absmartly' => drop)
      expect(output).to eq('')
      expect(context.pending_count).to be >= 1
    end
  end

  describe 'Fix #3: no redundant result variable in drop track' do
    it 'returns track result directly' do
      mock_ctx = double('context', track: 'tracked')
      d = ABsmartly::Liquid::Drop.new(mock_ctx)
      expect(d.track('goal')).to eq('tracked')
    end
  end

  describe 'Fix #5/#12: shared logging module' do
    it 'Logging module provides log_warning' do
      obj = Object.new
      obj.extend(ABsmartly::Liquid::Logging)
      expect(obj.respond_to?(:log_warning, true)).to eq(true)
    end

    it 'Logging module provides log_error' do
      obj = Object.new
      obj.extend(ABsmartly::Liquid::Logging)
      expect(obj.respond_to?(:log_error, true)).to eq(true)
    end

    it 'Drop has log_warning via Logging module' do
      expect(drop.respond_to?(:log_warning, true)).to eq(true)
    end

    it 'Drop has log_error via Logging module' do
      expect(drop.respond_to?(:log_error, true)).to eq(true)
    end
  end

  describe 'Fix #6: nil guard on @context access in filters' do
    it 'returns fallback when @context is nil (no absmartly drop)' do
      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_treatment }}")
      output = template.render({})
      expect(output).to eq('0')
    end

    it 'returns fallback for variable when @context is nil' do
      template = Liquid::Template.parse("{{ 'button_color' | absmartly_variable: 'default' }}")
      output = template.render({})
      expect(output).to eq('default')
    end
  end

  describe 'Fix #13: strict mode propagation in filter outer rescue' do
    it 'raises in strict mode when treatment filter hits an error' do
      ABsmartly::Liquid.strict_mode = true

      error_ctx = double('context', ready?: true)
      allow(error_ctx).to receive(:treatment).and_raise(StandardError, 'SDK error')
      error_drop = ABsmartly::Liquid::Drop.new(error_ctx)

      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_treatment }}")
      expect { template.render!('absmartly' => error_drop) }.to raise_error(StandardError, /SDK error/)
    end

    it 'raises in strict mode when peek filter hits an error' do
      ABsmartly::Liquid.strict_mode = true

      error_ctx = double('context', ready?: true)
      allow(error_ctx).to receive(:peek_treatment).and_raise(StandardError, 'SDK error')
      error_drop = ABsmartly::Liquid::Drop.new(error_ctx)

      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_peek }}")
      expect { template.render!('absmartly' => error_drop) }.to raise_error(StandardError, /SDK error/)
    end

    it 'raises in strict mode when variable filter hits an error' do
      ABsmartly::Liquid.strict_mode = true

      error_ctx = double('context', ready?: true)
      allow(error_ctx).to receive(:variable_value).and_raise(StandardError, 'SDK error')
      error_drop = ABsmartly::Liquid::Drop.new(error_ctx)

      template = Liquid::Template.parse("{{ 'key' | absmartly_variable: 'default' }}")
      expect { template.render!('absmartly' => error_drop) }.to raise_error(StandardError, /SDK error/)
    end

    it 'raises in strict mode when custom_field filter hits an error' do
      ABsmartly::Liquid.strict_mode = true

      error_ctx = double('context', ready?: true)
      allow(error_ctx).to receive(:custom_field_value).and_raise(StandardError, 'SDK error')
      error_drop = ABsmartly::Liquid::Drop.new(error_ctx)

      template = Liquid::Template.parse("{{ 'exp' | absmartly_custom_field: 'field' }}")
      expect { template.render!('absmartly' => error_drop) }.to raise_error(StandardError, /SDK error/)
    end

    it 'does not raise in non-strict mode when filter hits an error' do
      ABsmartly::Liquid.strict_mode = false

      error_ctx = double('context', ready?: true)
      allow(error_ctx).to receive(:treatment).and_raise(StandardError, 'SDK error')
      error_drop = ABsmartly::Liquid::Drop.new(error_ctx)

      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_treatment }}")
      output = template.render('absmartly' => error_drop)
      expect(output).to eq('0')
    end
  end

  describe 'Fix #14: get_absmartly_context no global fallback' do
    it 'returns nil when drop is not in context' do
      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_treatment }}")
      output = template.render({})
      expect(output).to eq('0')
      expect(log_output.string).to include('context missing')
    end

    it 'returns nil when drop does not respond to absmartly_context' do
      fake_drop = 'not_a_drop'
      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_treatment }}")
      output = template.render('absmartly' => fake_drop)
      expect(output).to eq('0')
    end
  end

  describe 'Fix #15: unified validation in Drop' do
    before { ABsmartly::Liquid.strict_mode = true }

    it 'validates experiment_name as non-empty string' do
      expect { drop.treatment('') }.to raise_error(ArgumentError, /Experiment name/)
      expect { drop.treatment(nil) }.to raise_error(ArgumentError, /Experiment name/)
      expect { drop.treatment(123) }.to raise_error(ArgumentError, /Experiment name/)
    end

    it 'validates variable_key as non-empty string' do
      expect { drop.variable('', 'default') }.to raise_error(ArgumentError, /Variable key/)
      expect { drop.variable(nil, 'default') }.to raise_error(ArgumentError, /Variable key/)
    end

    it 'validates field_name as non-empty string' do
      expect { drop.custom_field('exp', '') }.to raise_error(ArgumentError, /Field name/)
      expect { drop.custom_field('exp', nil) }.to raise_error(ArgumentError, /Field name/)
    end

    it 'validates goal_name as non-empty string' do
      expect { drop.track('') }.to raise_error(ArgumentError, /Goal name/)
      expect { drop.track(nil) }.to raise_error(ArgumentError, /Goal name/)
    end

    it 'logs error for invalid input in non-strict mode' do
      ABsmartly::Liquid.strict_mode = false
      drop.treatment('')
      expect(log_output.string).to include('Experiment name must be a non-empty string')
    end
  end

  describe 'Fix #9: consistent event shapes in test helper' do
    it 'TestEventHandler.publish wraps events via handle_event' do
      collector = TestEventCollector.new
      handler = TestEventHandler.new(collector)

      handler.publish(nil, { goal: 'test' })

      expect(collector.events.length).to eq(1)
      expect(collector.events.first).to have_key(:type)
      expect(collector.events.first[:type]).to eq('publish')
      expect(collector.events.first).to have_key(:data)
      expect(collector.events.first).to have_key(:timestamp)
    end
  end
end
