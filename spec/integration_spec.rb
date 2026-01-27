require 'spec_helper'
require 'liquid'

RSpec.describe 'Integration Scenarios' do
  let(:experiment_data) do
    {
      'experiments' => [
        {
          'id' => 1,
          'name' => 'exp_header',
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
            { 'name' => 'control', 'config' => '{"header_text":"Welcome"}' },
            { 'name' => 'treatment', 'config' => '{"header_text":"Hello!"}' }
          ],
          'audience' => '',
          'audienceStrict' => false
        },
        {
          'id' => 2,
          'name' => 'exp_button',
          'unitType' => 'session_id',
          'iteration' => 1,
          'seedHi' => 0,
          'seedLo' => 2,
          'split' => [0.5, 0.5],
          'trafficSeedHi' => 0,
          'trafficSeedLo' => 0,
          'trafficSplit' => [1.0, 0.0],
          'fullOnVariant' => 0,
          'applications' => [{ 'name' => 'test' }],
          'variants' => [
            { 'name' => 'control', 'config' => '{"button_color":"blue"}' },
            { 'name' => 'treatment', 'config' => '{"button_color":"green"}' }
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

  describe 'nested treatments' do
    it 'renders nested treatment tags correctly' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment 'exp_header' %}
          Header: {{ variant }}
          {% absmartly_treatment 'exp_button' %}
            Button: {{ variant }}
          {% endabsmartly_treatment %}
        {% endabsmartly_treatment %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to include('Header:')
      expect(output).to include('Button:')
    end

    it 'tracks exposures for both nested experiments' do
      initial_pending = context.pending_count

      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment 'exp_header' %}
          {% absmartly_treatment 'exp_button' %}
            Nested
          {% endabsmartly_treatment %}
        {% endabsmartly_treatment %}
      LIQUID

      template.render('absmartly' => drop)

      expect(context.pending_count).to be > initial_pending
    end
  end

  describe 'treatment with loops' do
    it 'renders treatment inside for loop' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% assign items = "1,2,3" | split: "," %}
        {% for item in items %}
          Item {{ item }}:
          {% absmartly_treatment 'exp_header' %}
            Variant: {{ variant }}
          {% endabsmartly_treatment %}
        {% endfor %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output.scan(/Item \d:/).count).to eq(3)
      expect(output.scan(/Variant:/).count).to eq(3)
    end

    it 'all loop iterations get same variant' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% assign items = "a,b,c" | split: "," %}
        {% for item in items %}
          {% absmartly_treatment 'exp_header' %}V{{ variant }}{% endabsmartly_treatment %}
        {% endfor %}
      LIQUID

      output = template.render('absmartly' => drop)
      variants = output.scan(/V(\d+)/).flatten

      expect(variants.uniq.count).to eq(1)
    end
  end

  describe 'treatment with conditionals' do
    it 'renders treatment inside if block' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% assign show_experiment = true %}
        {% if show_experiment %}
          {% absmartly_treatment 'exp_header' %}
            Variant: {{ variant }}
          {% endabsmartly_treatment %}
        {% endif %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to include('Variant:')
    end

    it 'does not render treatment when condition is false' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% assign show_experiment = false %}
        {% if show_experiment %}
          {% absmartly_treatment 'exp_header' %}
            Should Not Appear
          {% endabsmartly_treatment %}
        {% endif %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).not_to include('Should Not Appear')
    end
  end

  describe 'full page rendering' do
    it 'renders complete template with multiple experiments' do
      template = Liquid::Template.parse(<<~LIQUID)
        <html>
        <head><title>Test Page</title></head>
        <body>
          {% absmartly_treatment 'exp_header' %}
            {% if variant == 0 %}
              <h1>Welcome</h1>
            {% else %}
              <h1>Hello!</h1>
            {% endif %}
          {% endabsmartly_treatment %}

          <p>Content here</p>

          {% absmartly_treatment 'exp_button' %}
            {% if variant == 0 %}
              <button class="blue">Click</button>
            {% else %}
              <button class="green">Click</button>
            {% endif %}
          {% endabsmartly_treatment %}

          {% absmartly_track 'page_view' %}
        </body>
        </html>
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to include('<html>')
      expect(output).to include('</html>')
      expect(output).to include('<h1>')
      expect(output).to include('<button')
      expect(output).to include('Content here')
    end

    it 'renders filters mixed with tags' do
      template = Liquid::Template.parse(<<~LIQUID)
        Treatment via filter: {{ 'exp_header' | absmartly_treatment }}
        {% absmartly_treatment 'exp_button' %}
          Treatment via tag: {{ variant }}
        {% endabsmartly_treatment %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to include('Treatment via filter:')
      expect(output).to include('Treatment via tag:')
    end
  end

  describe 'treatment with variable values' do
    it 'uses variable values in templates' do
      template = Liquid::Template.parse(<<~LIQUID)
        {% absmartly_treatment 'exp_header' %}
          {% assign header = 'header_text' | absmartly_variable: 'Default' %}
          Header: {{ header }}
        {% endabsmartly_treatment %}
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to include('Header:')
    end
  end

  describe 'error recovery in complex templates' do
    it 'continues rendering after missing experiment' do
      template = Liquid::Template.parse(<<~LIQUID)
        Before
        {% absmartly_treatment 'nonexistent' %}
          Missing
        {% endabsmartly_treatment %}
        After
      LIQUID

      output = template.render('absmartly' => drop)

      expect(output).to include('Before')
      expect(output).to include('Missing')
      expect(output).to include('After')
    end

    it 'handles missing absmartly in complex template' do
      template = Liquid::Template.parse(<<~LIQUID)
        <div>
          {% absmartly_treatment 'exp_header' %}
            Content
          {% endabsmartly_treatment %}
        </div>
      LIQUID

      output = template.render({})

      expect(output).to include('<div>')
      expect(output).to include('</div>')
      expect(output).to include('Content')
    end
  end
end
