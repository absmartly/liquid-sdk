require 'spec_helper'
require 'liquid'

RSpec.describe ABsmartly::Liquid::Tags do
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
            { 'name' => 'control', 'config' => nil },
            { 'name' => 'treatment', 'config' => nil }
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

  describe 'TreatmentTag' do
    it 'makes variant available in block' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment 'exp_test' %}
          Variant: {{ variant }}
        {% endabsmartly_treatment %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to match(/Variant: 0/)
    end

    it 'tracks exposure' do
      initial_pending = context.pending_count

      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment 'exp_test' %}
          {{ variant }}
        {% endabsmartly_treatment %}
      LIQUID

      template.render('absmartly' => drop)

      expect(context.pending_count).to be > initial_pending
    end

    it 'allows conditional rendering based on variant' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment 'exp_test' %}
          {% if variant == 0 %}
            Control
          {% elsif variant == 1 %}
            Treatment
          {% endif %}
        {% endabsmartly_treatment %}
      LIQUID

      output = template.render('absmartly' => drop).strip

      expect(output).to eq('Control')
    end

    it 'handles missing experiment gracefully' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment 'nonexistent_experiment' %}
          Variant: {{ variant }}
        {% endabsmartly_treatment %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to match(/Variant: 0/)
    end

    it 'returns variant 0 when absmartly drop is missing' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment 'exp_test' %}
          Variant: {{ variant }}
        {% endabsmartly_treatment %}
      LIQUID

      output = template.render({})

      expect(output).to match(/Variant: 0/)
    end

    it 'continues rendering after treatment block' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment 'exp_test' %}
          Treatment
        {% endabsmartly_treatment %}
        After Block
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to include('Treatment')
      expect(output).to include('After Block')
    end

    it 'raises syntax error for invalid syntax' do
      expect {
        Liquid::Template.parse("{% absmartly_treatment %}")
      }.to raise_error(Liquid::SyntaxError)
    end

    it 'handles context that is not ready' do
      not_ready_context = double('context',
        ready?: false,
        treatment: 0
      )
      not_ready_drop = ABsmartly::Liquid::Drop.new(not_ready_context)

      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment 'exp_test' %}
          Variant: {{ variant }}
        {% endabsmartly_treatment %}
      LIQUID

      output = template.render('absmartly' => not_ready_drop)

      expect(output).to match(/Variant: 0/)
    end
  end

  describe 'TrackTag' do
    it 'tracks goal' do
      initial_pending = context.pending_count

      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_track 'purchase', amount: 99.99, items: 3 %}
      LIQUID

      template.render('absmartly' => drop)

      expect(context.pending_count).to be > initial_pending
    end

    it 'returns empty string' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_track 'purchase', amount: 99.99 %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output.strip).to eq('')
    end

    it 'handles goal without properties' do
      initial_pending = context.pending_count

      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_track 'pageview' %}
      LIQUID

      template.render('absmartly' => drop)

      expect(context.pending_count).to be > initial_pending
    end

    it 'handles missing absmartly drop gracefully' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_track 'purchase', amount: 99.99 %}
      LIQUID

      output = template.render({})

      expect(output.strip).to eq('')
    end

    it 'raises syntax error for invalid syntax' do
      expect {
        Liquid::Template.parse("{% absmartly_track %}")
      }.to raise_error(Liquid::SyntaxError)
    end
  end

  describe 'TreatmentTag attribute parsing' do
    it 'parses experiment name from variable' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% assign exp_name = 'exp_test' %}
        {% absmartly_treatment exp_name %}
          Variant: {{ variant }}
        {% endabsmartly_treatment %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to match(/Variant: 0/)
    end

    it 'parses quoted experiment name' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment "exp_test" %}
          Variant: {{ variant }}
        {% endabsmartly_treatment %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to match(/Variant: 0/)
    end
  end

  describe 'TrackTag property parsing' do
    it 'parses variable properties' do
      initial_pending = context.pending_count

      template = Liquid::Template.parse(<<~LIQUID)
        {% assign price = 49.99 %}
        {% absmartly_track 'purchase', amount: price %}
      LIQUID

      template.render('absmartly' => drop)

      expect(context.pending_count).to be > initial_pending
    end

    it 'parses string properties' do
      initial_pending = context.pending_count

      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_track 'signup', source: 'homepage' %}
      LIQUID

      template.render('absmartly' => drop)

      expect(context.pending_count).to be > initial_pending
    end
  end
end
