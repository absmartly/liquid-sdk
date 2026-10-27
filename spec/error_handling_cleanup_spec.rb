require 'spec_helper'
require 'logger'
require 'stringio'

RSpec.describe 'Liquid wrapper error handling cleanup' do
  let(:log_output) { StringIO.new }

  around do |example|
    original_logger = ABsmartly::Liquid.logger
    original_strict = ABsmartly::Liquid.strict_mode
    ABsmartly::Liquid.logger = Logger.new(log_output)
    example.run
  ensure
    ABsmartly::Liquid.logger = original_logger
    ABsmartly::Liquid.strict_mode = original_strict
  end

  it 'raises a dedicated error once for a missing context in strict mode' do
    ABsmartly::Liquid.strict_mode = true

    expect { Liquid::Template.parse("{{ 'exp' | absmartly_treatment }}").render! }
      .to raise_error(ABsmartly::Liquid::ContextUnavailableError, 'ABsmartly context not available')
    expect(log_output.string.scan('ABsmartly context missing').size).to eq(1)
    expect(log_output.string).not_to include('ABsmartly treatment error')
  end

  it 'raises the dedicated missing-context error from the tracking filter' do
    ABsmartly::Liquid.strict_mode = true

    expect { Liquid::Template.parse("{{ 'goal' | absmartly_track }}").render! }
      .to raise_error(ABsmartly::Liquid::ContextUnavailableError, 'ABsmartly context not available')
  end

  it 'raises the dedicated missing-context error from the treatment tag' do
    ABsmartly::Liquid.strict_mode = true

    expect do
      Liquid::Template.parse("{% absmartly_treatment 'exp' %}{{ variant }}{% endabsmartly_treatment %}").render!
    end.to raise_error(ABsmartly::Liquid::ContextUnavailableError, 'ABsmartly context not available')
  end

  it 'raises the dedicated missing-context error from the tracking tag' do
    ABsmartly::Liquid.strict_mode = true

    expect { Liquid::Template.parse("{% absmartly_track 'goal' %}").render! }
      .to raise_error(ABsmartly::Liquid::ContextUnavailableError, 'ABsmartly context not available')
  end

  it 'continues to treatment handling when a treatment tag readiness check fails' do
    ABsmartly::Liquid.strict_mode = false
    facade = Class.new(Liquid::Drop) do
      def ready?
        raise 'ready failed'
      end

      def treatment(_name)
        1
      end
    end.new

    output = Liquid::Template.parse("{% absmartly_treatment 'exp' %}{{ variant }}{% endabsmartly_treatment %}")
      .render!('absmartly' => facade)

    expect(output).to eq('1')
    expect(log_output.string).to include('ABsmartly readiness error: ready failed')
  end

  it 'raises treatment tag readiness failures in strict mode' do
    ABsmartly::Liquid.strict_mode = true
    facade = Class.new(Liquid::Drop) do
      def ready?
        raise 'ready failed'
      end
    end.new

    expect do
      Liquid::Template.parse("{% absmartly_treatment 'exp' %}{{ variant }}{% endabsmartly_treatment %}")
        .render!('absmartly' => facade)
    end.to raise_error(RuntimeError, 'ready failed')
  end
end
