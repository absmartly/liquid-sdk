# ABsmartly Liquid SDK

A/B testing SDK for [Shopify Liquid](https://shopify.github.io/liquid/) templating language and [Jekyll](https://jekyllrb.com/) static site generator. This SDK brings the power of ABsmartly's experimentation platform to server-side rendered templates.

## Compatibility

The ABsmartly Liquid SDK is compatible with:

- **Ruby**: Version 3.0 and later
- **Liquid**: Version 5.0 and later
- **Shopify Themes**: All modern Shopify themes
- **Jekyll**: Version 4.0 and later

**Note on Naming:** This SDK uses the module name `ABsmartly::Liquid` (with namespace) to avoid clashing with the Ruby SDK's main module (`Absmartly`). When requiring the gem, use `require 'absmartly/liquid'`.

## Installation

Add to your `Gemfile`:

```ruby
gem 'absmartly-liquid-sdk'
```

Then run:

```bash
bundle install
```

For Jekyll sites, also add to your `_config.yml`:

```yaml
plugins:
  - absmartly-liquid-sdk
```

## Getting Started

Please follow the [installation](#installation) instructions before trying the following code.

### Initialization

This example assumes an API Key, an Application, and an Environment have been created in the ABsmartly web console.

```ruby
require 'absmartly/liquid'

sdk = ABSmartly::SDK.new(
  endpoint: 'https://your-company.absmartly.io/v1',
  api_key: ENV['ABSMARTLY_API_KEY'],
  application: 'my-shopify-store',
  environment: 'production'
)
```

#### With Optional Parameters

```ruby
sdk = ABSmartly::SDK.new(
  endpoint: 'https://your-company.absmartly.io/v1',
  api_key: ENV['ABSMARTLY_API_KEY'],
  application: 'my-shopify-store',
  environment: 'production',
  retries: 3,
  timeout: 5000
)
```

**SDK Options**

| Option       | Type      | Required? | Default | Description                                                                                                                                                                   |
| :----------- | :-------- | :-------: | :-----: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| endpoint     | `String`  |  &#9989;  |  `nil`  | The URL to your API endpoint. Most commonly `"https://your-company.absmartly.io/v1"`                                                                                         |
| api_key      | `String`  |  &#9989;  |  `nil`  | Your API key which can be found on the Web Console.                                                                                                                           |
| environment  | `String`  |  &#9989;  |  `nil`  | The environment of the platform where the SDK is installed. Environments are created on the Web Console.                                                                      |
| application  | `String`  |  &#9989;  |  `nil`  | The name of the application where the SDK is installed. Applications are created on the Web Console.                                                                          |
| retries      | `Integer` | &#10060;  |   `5`   | Maximum number of HTTP retries for failed requests                                                                                                                            |
| timeout      | `Integer` | &#10060;  | `3000`  | HTTP timeout in milliseconds                                                                                                                                                  |
| event_logger | `Proc`    | &#10060;  |  `nil`  | Custom event logger callback (see Advanced section)                                                                                                                           |

## Creating a New Context

### Synchronously

```ruby
context = sdk.create_context(
  units: {
    session_id: session[:id],
    customer_id: current_customer&.id
  }
)

context.ready

drop = ABSmartly::Liquid::Drop.new(context)
```

### With Pre-fetched Data

For better performance, pre-fetch context data and reuse it to avoid an additional round-trip.

```ruby
data = sdk.get_client.get_context(
  units: { session_id: session[:id] }
)

context = sdk.create_context_with(
  { units: { session_id: session[:id] } },
  data
)

drop = ABSmartly::Liquid::Drop.new(context)
```

### Refreshing the Context with Fresh Experiment Data

For long-running contexts, the context is usually created once when the application is first started. However, any experiments started after the context was created will not be triggered.

```ruby
context = sdk.create_context(
  units: { session_id: session[:id] },
  refresh_period: 4 * 60 * 60 * 1000
)

# Or refresh manually
context.refresh
```

### Setting Extra Units

You can add additional units to a context. This may be used, for example, when a user logs in to your application.

**Note:** You cannot override an already set unit type as that would be a change of identity. In this case, you must create a new context instead.

```ruby
context.set_unit('db_user_id', '1000013')
```

## Basic Usage

### Treatment Selection with Filters

Use the `absmartly_treatment` filter to select a treatment variant:

```liquid
{% assign variant = 'exp_button_color' | absmartly_treatment %}

{% if variant == 0 %}
  <button class="btn-blue">Buy Now</button>
{% elsif variant == 1 %}
  <button class="btn-red">Buy Now</button>
{% endif %}
```

### Treatment Selection with Block Tag

Use the block tag for cleaner syntax with a local `variant` variable:

```liquid
{% absmartly_treatment 'exp_button_color' %}
  {% if variant == 0 %}
    <button class="btn-blue">Buy Now</button>
  {% elsif variant == 1 %}
    <button class="btn-red">Buy Now</button>
  {% endif %}
{% endabsmartly_treatment %}
```

### Treatment Variables

Variables allow you to configure experiment variations without code changes:

```liquid
{% assign button_text = 'checkout_button_text' | absmartly_variable: 'Checkout' %}
{% assign button_color = 'checkout_button_color' | absmartly_variable: 'blue' %}

<a href="/checkout" class="btn btn-{{ button_color }}">
  {{ button_text }}
</a>
```

### Peek at Treatment Variants

Although generally not recommended, it is sometimes necessary to peek at a treatment without triggering an exposure.

```liquid
{% assign variant = 'exp_feature' | absmartly_peek %}
```

#### Peeking at Variables

```liquid
{% assign color = 'button_color' | absmartly_peek_variable: 'blue' %}
```

### Overriding Treatment Variants

During development, force specific variants:

```ruby
context.override('exp_test', 1)

context.overrides({
  'exp_test' => 1,
  'exp_another' => 0
})
```

### Tracking Goals

Track goal achievement with properties:

```liquid
<!-- Using filter -->
{{ 'purchase' | absmartly_track: amount: order.total_price, items: order.line_items.size }}

<!-- Using tag -->
{% absmartly_track 'add_to_cart', product_id: product.id, price: product.price %}
```

## Advanced

### Context Attributes

Add metadata for audience targeting:

```ruby
context.attributes({
  user_agent: request.user_agent,
  customer_age: 'new_customer',
  account_type: 'premium'
})
```

### Publishing Pending Data

Ensure all events are published before proceeding:

```ruby
context.publish
```

### Finalizing

The `close` method will ensure all events have been published to the ABsmartly collector, like `publish`, and will also "seal" the context, preventing any further events from being tracked.

```ruby
context.close
```

### Custom Event Logger

Monitor SDK events for debugging, analytics, or integrating with other systems.

```ruby
event_logger = ->(context, event_name, data) {
  case event_name
  when 'exposure'
    Rails.logger.info "ABsmartly exposure: #{data[:name]}"
  when 'goal'
    Rails.logger.info "ABsmartly goal: #{data[:name]}"
  when 'error'
    Rails.logger.error "ABsmartly error: #{data}"
  when 'ready'
    Rails.logger.info "ABsmartly context ready"
  when 'refresh'
    Rails.logger.info "ABsmartly context refreshed"
  when 'publish'
    Rails.logger.info "ABsmartly events published"
  when 'close'
    Rails.logger.info "ABsmartly context closed"
  end
}

sdk = ABSmartly::SDK.new(
  endpoint: ENV['ABSMARTLY_ENDPOINT'],
  api_key: ENV['ABSMARTLY_API_KEY'],
  application: 'my-store',
  environment: Rails.env,
  event_logger: event_logger
)
```

**Event Types**

| Event      | When                                         | Data                                 |
| :--------- | :------------------------------------------- | :----------------------------------- |
| `ready`    | Context turns ready                          | Context initialization data          |
| `refresh`  | `refresh()` succeeds                         | Refreshed context data               |
| `publish`  | `publish()` succeeds                         | Published events                     |
| `exposure` | `treatment()` succeeds on first exposure     | Exposure data                        |
| `goal`     | `track()` succeeds                           | Goal data                            |
| `close`    | `close()` succeeds the first time            | `nil`                                |
| `error`    | Error occurs                                 | Error object                         |

## Liquid API Reference

### Filters

| Filter                    | Description                                     | Returns                          |
| :------------------------ | :---------------------------------------------- | :------------------------------- |
| `absmartly_treatment`     | Get treatment variant and track exposure         | Integer variant number (0, 1, ...) |
| `absmartly_peek`          | Get treatment variant without tracking exposure  | Integer variant number           |
| `absmartly_variable`      | Get variable value and track exposure            | Variable value or default        |
| `absmartly_peek_variable` | Get variable value without tracking exposure     | Variable value or default        |
| `absmartly_custom_field`  | Get custom field value for an experiment         | Parsed field value               |
| `absmartly_track`         | Track goal achievement with properties           | Empty string                     |

### Tags

| Tag                           | Description                                     |
| :---------------------------- | :---------------------------------------------- |
| `{% absmartly_treatment %}` | Block tag for treatment with local `variant` variable |
| `{% absmartly_track %}`     | Tag for tracking goals with properties           |

### Drop Object

The `absmartly` drop object is available in templates when injected via `ABSmartly::Liquid::Drop.new(context)`:

```liquid
{% if absmartly.ready %}
  <!-- Context is ready -->
{% endif %}

{% for exp in absmartly.experiments %}
  <li>{{ exp }}</li>
{% endfor %}
```

## Platform-Specific Examples

### Using with Shopify / Rails

```ruby
class ApplicationController < ActionController::Base
  before_action :init_absmartly
  after_action :close_absmartly

  private

  def init_absmartly
    $absmartly_sdk ||= ABSmartly::SDK.new(
      endpoint: ENV['ABSMARTLY_ENDPOINT'],
      api_key: ENV['ABSMARTLY_API_KEY'],
      application: 'my-shopify-store',
      environment: Rails.env
    )

    @context = $absmartly_sdk.create_context(
      units: {
        session_id: session[:id],
        customer_id: current_customer&.id
      }
    )

    @context.ready

    @context.attributes({
      user_agent: request.user_agent,
      customer_logged_in: current_customer.present?
    })

    @absmartly_drop = ABSmartly::Liquid::Drop.new(@context)
  rescue => e
    Rails.logger.error "ABsmartly initialization failed: #{e.message}"
    @absmartly_drop = nil
  end

  def close_absmartly
    @context&.close
  end
end
```

In your template:

```liquid
{% if absmartly.ready %}
  {% assign header_color = 'header_color' | absmartly_variable: 'blue' %}
  <header style="background: {{ header_color }}">
    {% render 'header' %}
  </header>
{% else %}
  <header style="background: blue">
    {% render 'header' %}
  </header>
{% endif %}
```

### Using with Jekyll

```ruby
# _plugins/absmartly.rb
require 'absmartly/liquid'

Jekyll::Hooks.register :site, :pre_render do |site|
  sdk = ABSmartly::SDK.new(
    endpoint: ENV['ABSMARTLY_ENDPOINT'],
    api_key: ENV['ABSMARTLY_API_KEY'],
    application: 'jekyll-site',
    environment: ENV['JEKYLL_ENV'] || 'development'
  )

  context = sdk.create_context(
    units: { site_id: site.config['url'] }
  )
  context.ready

  drop = ABSmartly::Liquid::Drop.new(context)
  site.config['absmartly'] = drop
end
```

In your Jekyll template:

```liquid
{% assign hero_variant = 'exp_homepage_hero' | absmartly_treatment %}

{% if hero_variant == 0 %}
  {% include hero-v1.html %}
{% elsif hero_variant == 1 %}
  {% include hero-v2.html %}
{% endif %}
```

## About A/B Smartly

**A/B Smartly** is the leading provider of state-of-the-art, on-premises, full-stack experimentation platforms for engineering and product teams that want to confidently deploy features as fast as they can develop them.
A/B Smartly's real-time analytics helps engineering and product teams ensure that new features will improve the customer experience without breaking or degrading performance and/or business metrics.

### Have a look at our growing list of clients and SDKs:

- [JavaScript SDK](https://www.github.com/absmartly/javascript-sdk)
- [Java SDK](https://www.github.com/absmartly/java-sdk)
- [PHP SDK](https://www.github.com/absmartly/php-sdk)
- [Swift SDK](https://www.github.com/absmartly/swift-sdk)
- [Vue2 SDK](https://www.github.com/absmartly/vue2-sdk)
- [Vue3 SDK](https://www.github.com/absmartly/vue3-sdk)
- [React SDK](https://www.github.com/absmartly/react-sdk)
- [Python3 SDK](https://www.github.com/absmartly/python3-sdk)
- [Go SDK](https://www.github.com/absmartly/go-sdk)
- [Ruby SDK](https://www.github.com/absmartly/ruby-sdk)
- [.NET SDK](https://www.github.com/absmartly/dotnet-sdk)
- [Dart SDK](https://www.github.com/absmartly/dart-sdk)
- [Flutter SDK](https://www.github.com/absmartly/flutter-sdk)
- [Liquid SDK](https://www.github.com/absmartly/liquid-sdk) (this package)
