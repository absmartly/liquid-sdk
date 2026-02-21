module TestDataHelpers
  def build_experiment_data
    {
      'experiments' => [
        {
          'id' => 1,
          'name' => 'exp_test_ab',
          'unitType' => 'session_id',
          'iteration' => 1,
          'seedHi' => 0x00000000,
          'seedLo' => 0x00000000,
          'split' => [0.5, 0.5],
          'trafficSeedHi' => 0x00000000,
          'trafficSeedLo' => 0x00000000,
          'trafficSplit' => [0.0, 1.0],
          'fullOnVariant' => 0,
          'applications' => [
            {
              'name' => 'website'
            }
          ],
          'variants' => [
            {
              'name' => 'A',
              'config' => {
                'banner.border' => 1,
                'banner.size' => 'large'
              }.to_json
            },
            {
              'name' => 'B',
              'config' => {
                'banner.border' => 0,
                'banner.size' => 'small'
              }.to_json
            }
          ]
        },
        {
          'id' => 2,
          'name' => 'exp_test_abc',
          'unitType' => 'session_id',
          'iteration' => 1,
          'seedHi' => 0x00000000,
          'seedLo' => 0x00000001,
          'split' => [0.33, 0.33, 0.34],
          'trafficSeedHi' => 0x00000000,
          'trafficSeedLo' => 0x00000001,
          'trafficSplit' => [0.0, 1.0],
          'fullOnVariant' => 0,
          'applications' => [
            {
              'name' => 'website'
            }
          ],
          'variants' => [
            {
              'name' => 'A',
              'config' => nil
            },
            {
              'name' => 'B',
              'config' => nil
            },
            {
              'name' => 'C',
              'config' => nil
            }
          ]
        },
        {
          'id' => 3,
          'name' => 'exp_test_not_eligible',
          'unitType' => 'session_id',
          'iteration' => 1,
          'seedHi' => 0x00000000,
          'seedLo' => 0x00000002,
          'split' => [0.5, 0.5],
          'trafficSeedHi' => 0x00000000,
          'trafficSeedLo' => 0x00000002,
          'trafficSplit' => [0.99, 0.01],
          'fullOnVariant' => 0,
          'applications' => [
            {
              'name' => 'website'
            }
          ],
          'variants' => [
            {
              'name' => 'A',
              'config' => nil
            },
            {
              'name' => 'B',
              'config' => nil
            }
          ]
        },
        {
          'id' => 4,
          'name' => 'exp_test_fullon',
          'unitType' => 'session_id',
          'iteration' => 1,
          'seedHi' => 0x00000000,
          'seedLo' => 0x00000003,
          'split' => [0.25, 0.25, 0.25, 0.25],
          'trafficSeedHi' => 0x00000000,
          'trafficSeedLo' => 0x00000003,
          'trafficSplit' => [0.0, 1.0],
          'fullOnVariant' => 2,
          'applications' => [
            {
              'name' => 'website'
            }
          ],
          'variants' => [
            {
              'name' => 'A',
              'config' => nil
            },
            {
              'name' => 'B',
              'config' => nil
            },
            {
              'name' => 'C',
              'config' => nil
            },
            {
              'name' => 'D',
              'config' => nil
            }
          ]
        }
      ]
    }
  end
end

RSpec.shared_context 'with absmartly test context' do
  include TestDataHelpers

  let(:experiment_data) { build_experiment_data }
  let(:event_collector) { TestEventCollector.new }
  let(:units) { { session_id: 'test-session-123' } }
  let(:context) { create_test_context(units: units, data: experiment_data, event_collector: event_collector) }
  let(:drop) { ABsmartly::Liquid::Drop.new(context) }
end

RSpec.configure do |config|
  config.include TestDataHelpers
end
