require 'spec_helper'

RSpec.describe ABsmartly::Liquid::Drop do
  let(:context) do
    double('context',
      ready?: true,
      failed?: false,
      closed?: false,
      experiments: ['exp1', 'exp2'],
      pending_count: 2,
      treatment: 1,
      peek_treatment: 0,
      variable_value: 'red',
      peek_variable_value: 'blue',
      custom_field_value: 'metadata_value',
      track: nil,
      data: { 'experiments' => [] },
      units: { 'session_id' => 'test123' }
    )
  end

  let(:drop) { described_class.new(context) }

  describe '#ready' do
    it 'returns ready state' do
      expect(drop.ready).to eq(true)
    end
  end

  describe '#failed' do
    it 'returns failed state' do
      expect(drop.failed).to eq(false)
    end
  end

  describe '#finalized' do
    it 'returns finalized state' do
      expect(drop.finalized).to eq(false)
    end
  end

  describe '#experiments' do
    it 'returns list of experiments' do
      expect(drop.experiments).to eq(['exp1', 'exp2'])
    end
  end

  describe '#pending' do
    it 'returns pending count' do
      expect(drop.pending).to eq(2)
    end
  end

  describe '#treatment' do
    it 'calls context treatment' do
      expect(context).to receive(:treatment).with('exp_test')
      drop.treatment('exp_test')
    end

    it 'returns variant' do
      expect(drop.treatment('exp_test')).to eq(1)
    end
  end

  describe '#peek' do
    it 'calls context peek_treatment' do
      expect(context).to receive(:peek_treatment).with('exp_test')
      drop.peek('exp_test')
    end

    it 'returns variant' do
      expect(drop.peek('exp_test')).to eq(0)
    end
  end

  describe '#variable' do
    it 'calls context variable_value' do
      expect(context).to receive(:variable_value).with('button_color', 'blue')
      drop.variable('button_color', 'blue')
    end

    it 'returns value' do
      expect(drop.variable('button_color', 'blue')).to eq('red')
    end
  end

  describe '#peek_variable' do
    it 'calls context peek_variable_value' do
      expect(context).to receive(:peek_variable_value).with('button_color', 'blue')
      drop.peek_variable('button_color', 'blue')
    end

    it 'returns value' do
      expect(drop.peek_variable('button_color', 'blue')).to eq('blue')
    end
  end

  describe '#custom_field' do
    it 'calls context custom_field_value' do
      expect(context).to receive(:custom_field_value).with('exp_test', 'metadata')
      drop.custom_field('exp_test', 'metadata')
    end

    it 'returns value' do
      expect(drop.custom_field('exp_test', 'metadata')).to eq('metadata_value')
    end
  end

  describe '#track' do
    it 'calls context track' do
      expect(context).to receive(:track).with('purchase', { amount: 99.99 })
      drop.track('purchase', { amount: 99.99 })
    end

    it 'returns nil' do
      expect(drop.track('purchase')).to be_nil
    end
  end

  describe '#data' do
    it 'returns context data' do
      expect(drop.data).to eq({ 'experiments' => [] })
    end
  end

  describe '#units' do
    it 'returns context units' do
      expect(drop.units).to eq({ 'session_id' => 'test123' })
    end
  end
end
