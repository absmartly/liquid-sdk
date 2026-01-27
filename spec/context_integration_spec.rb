require 'spec_helper'
require 'liquid'

RSpec.describe 'Context Integration' do
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

  describe 'context availability in template' do
    it 'makes context ready state accessible via drop' do
      template = Liquid::Template.parse("Ready: {{ absmartly.ready }}")
      output = template.render('absmartly' => drop)

      expect(output).to include('Ready: true')
    end

    it 'makes context finalized state accessible via drop' do
      template = Liquid::Template.parse("Finalized: {{ absmartly.finalized }}")
      output = template.render('absmartly' => drop)

      expect(output).to include('Finalized: false')
    end

    it 'makes experiments list accessible' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% for exp in absmartly.experiments %}
          Experiment: {{ exp }}
        {% endfor %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to include('Experiment: exp_test')
    end

    it 'makes pending count accessible' do
      template = Liquid::Template.parse("Pending: {{ absmartly.pending }}")
      output = template.render('absmartly' => drop)

      expect(output).to match(/Pending: \d+/)
    end
  end

  describe 'context methods callable from template' do
    it 'allows treatment method call via drop' do
      template = Liquid::Template.parse("Variant: {{ absmartly.treatment['exp_test'] }}")

      expect { template.render('absmartly' => drop) }.not_to raise_error
    end

    it 'allows peek method call via drop' do
      expect(drop.peek('exp_test')).to be_a(Integer)
    end

    it 'allows variable method call via drop' do
      result = drop.variable('button_color', 'default')
      expect(result).to eq('blue').or eq('default')
    end

    it 'allows peek_variable method call via drop' do
      result = drop.peek_variable('button_color', 'default')
      expect(result).to eq('blue').or eq('default')
    end
  end

  describe 'context data access' do
    it 'provides access to raw context data' do
      expect(drop.data).not_to be_nil
    end
  end

  describe 'context state checks' do
    it 'reports ready state correctly' do
      expect(drop.ready).to eq(true)
    end

    it 'reports finalized state correctly' do
      expect(drop.finalized).to eq(false)
    end

    it 'reports closed state correctly' do
      expect(drop.closed).to eq(false)
    end
  end

  describe 'thread safety with mock context' do
    it 'maintains separate context per drop instance' do
      mock_context1 = double('context1',
        ready?: true,
        units: { 'session_id' => 'test123' }
      )
      mock_context2 = double('context2',
        ready?: true,
        units: { 'session_id' => 'test456' }
      )

      drop1 = ABsmartly::Liquid::Drop.new(mock_context1)
      drop2 = ABsmartly::Liquid::Drop.new(mock_context2)

      expect(drop1.units['session_id']).to eq('test123')
      expect(drop2.units['session_id']).to eq('test456')
    end

    it 'drop instances do not share state' do
      mock_context1 = double('context1',
        pending_count: 5
      )
      mock_context2 = double('context2',
        pending_count: 10
      )

      drop1 = ABsmartly::Liquid::Drop.new(mock_context1)
      drop2 = ABsmartly::Liquid::Drop.new(mock_context2)

      expect(drop1.pending).to eq(5)
      expect(drop2.pending).to eq(10)
    end
  end

  describe 'underlying context access' do
    it 'provides access to underlying absmartly context' do
      expect(drop.absmartly_context).to eq(context)
    end

    it 'absmartly_context is the original context object' do
      expect(drop.absmartly_context).to respond_to(:treatment)
      expect(drop.absmartly_context).to respond_to(:track)
    end
  end
end
