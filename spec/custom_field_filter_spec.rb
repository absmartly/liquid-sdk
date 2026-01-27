require 'spec_helper'
require 'liquid'

RSpec.describe 'Custom Field Filters' do
  describe '#absmartly_custom_field filter' do
    let(:mock_context) do
      double('context',
        ready?: true,
        custom_field_value: nil
      )
    end

    let(:drop) { ABsmartly::Liquid::Drop.new(mock_context) }

    it 'returns string custom field value' do
      allow(mock_context).to receive(:custom_field_value).with('exp_test', 'category').and_return('premium')

      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_custom_field: 'category' }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('premium')
    end

    it 'returns number custom field value' do
      allow(mock_context).to receive(:custom_field_value).with('exp_test', 'priority').and_return(100)

      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_custom_field: 'priority' }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('100')
    end

    it 'returns boolean custom field value' do
      allow(mock_context).to receive(:custom_field_value).with('exp_test', 'enabled').and_return(true)

      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_custom_field: 'enabled' }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('true')
    end

    it 'returns empty string for missing custom field' do
      allow(mock_context).to receive(:custom_field_value).with('exp_test', 'nonexistent').and_return(nil)

      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_custom_field: 'nonexistent' }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('')
    end

    it 'returns empty string for missing experiment' do
      allow(mock_context).to receive(:custom_field_value).with('nonexistent_exp', 'category').and_return(nil)

      template = Liquid::Template.parse("{{ 'nonexistent_exp' | absmartly_custom_field: 'category' }}")
      output = template.render('absmartly' => drop)

      expect(output).to eq('')
    end

    it 'returns empty string when context not ready' do
      not_ready_context = double('context', ready?: false)
      not_ready_drop = ABsmartly::Liquid::Drop.new(not_ready_context)

      template = Liquid::Template.parse("{{ 'exp_test' | absmartly_custom_field: 'category' }}")
      output = template.render('absmartly' => not_ready_drop)

      expect(output).to eq('')
    end
  end

  describe '#custom_field drop method' do
    let(:mock_context) do
      double('context',
        custom_field_value: nil
      )
    end

    let(:drop) { ABsmartly::Liquid::Drop.new(mock_context) }

    it 'returns string custom field value via drop' do
      allow(mock_context).to receive(:custom_field_value).with('exp_test', 'category').and_return('premium')

      expect(drop.custom_field('exp_test', 'category')).to eq('premium')
    end

    it 'returns number custom field value via drop' do
      allow(mock_context).to receive(:custom_field_value).with('exp_test', 'priority').and_return(100)

      expect(drop.custom_field('exp_test', 'priority')).to eq(100)
    end

    it 'returns boolean custom field value via drop' do
      allow(mock_context).to receive(:custom_field_value).with('exp_test', 'enabled').and_return(true)

      expect(drop.custom_field('exp_test', 'enabled')).to eq(true)
    end

    it 'returns nil for missing custom field via drop' do
      allow(mock_context).to receive(:custom_field_value).with('exp_test', 'nonexistent').and_return(nil)

      expect(drop.custom_field('exp_test', 'nonexistent')).to be_nil
    end

    it 'delegates to context custom_field_value method' do
      expect(mock_context).to receive(:custom_field_value).with('exp_test', 'field_name')
      drop.custom_field('exp_test', 'field_name')
    end
  end
end
