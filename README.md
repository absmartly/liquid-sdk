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

### For Shopify Apps

Add to your `Gemfile`:

```ruby
gem 'absmartly-liquid-sdk'
```

Then run:

```bash
bundle install
```

### For Jekyll Sites

Add to your `Gemfile`:

```ruby
gem 'absmartly-liquid-sdk'
```

Then in your `_config.yml`:

```yaml
plugins:
  - absmartly-liquid-sdk
```

## Getting Started

### Initialization

Initialize the SDK in your Ruby code (controller, initializer, or plugin):

```ruby
require 'absmartly/liquid'

# Create SDK instance
sdk = ABSmartly::SDK.new(
  endpoint: 'https://your-company.absmartly.io/v1',
  api_key: ENV['ABSMARTLY_API_KEY'],
  application: 'my-shopify-store',
  environment: 'production'
)
```

**SDK Options**

| Option | Type | Required? | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| endpoint | `String` | &#9989; | `nil` | The URL to your API endpoint. Most commonly `"https://your-company.absmartly.io/v1"` |
| api_key | `String` | &#9989; | `nil` | Your API key which can be found on the Web Console. |
| environment | `String` | &#9989; | `nil` | The environment of the platform where the SDK is installed. Environments are created on the Web Console. |
| application | `String` | &#9989; | `nil` | The name of the application where the SDK is installed. Applications are created on the Web Console. |
| retries | `Integer` | &#10060; | `5` | Maximum number of HTTP retries for failed requests |
| timeout | `Integer` | &#10060; | `3000` | HTTP timeout in milliseconds |
| event_logger | `Proc` | &#10060; | `nil` | Custom event logger callback (see Advanced section) |

### Create Context

Create a context before rendering Liquid templates:

#### Shopify App Example

```ruby
class ApplicationController < ActionController::Base
  before_action :init_absmartly

  private

  def init_absmartly
    # Create context with user identifiers
    @context = $absmartly_sdk.create_context(
      units: {
        session_id: session[:id],
        customer_id: current_customer&.id
      }
    )

    # Wait for context to be ready
    @context.ready

    # Create Liquid drop for template access
    @absmartly_drop = ABSmartly::Liquid::Drop.new(@context)
  end
end
```

#### Render Template with Context

```ruby
# In controller
render 'template', assigns: { 'absmartly' => @absmartly_drop }
```

#### With Pre-fetched Data (Recommended)

For better performance, pre-fetch context data and reuse it:

```ruby
# Fetch data once (can be cached)
data = sdk.get_client.get_context(
  units: { session_id: session[:id] }
)

# Create context with data (no HTTP call)
context = sdk.create_context_with(
  { units: { session_id: session[:id] } },
  data
)

# Context is immediately ready
drop = ABSmartly::Liquid::Drop.new(context)
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

Use the block tag for cleaner syntax with local `variant` variable:

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

### Tracking Goals

Track goal achievement with properties:

```liquid
<!-- Using filter -->
{{ 'purchase' | absmartly_track: amount: order.total_price, items: order.line_items.size }}

<!-- Using tag -->
{% absmartly_track 'add_to_cart', product_id: product.id, price: product.price %}
```

### Peek Without Tracking

Sometimes you need to check a treatment without triggering an exposure:

```liquid
{% assign variant = 'exp_feature' | absmartly_peek %}
```

## Liquid API Reference

### Filters

#### `absmartly_treatment`

Get treatment variant and track exposure.

```liquid
{{ 'experiment_name' | absmartly_treatment }}
```

**Returns:** Integer variant number (0, 1, 2, ...)

#### `absmartly_peek`

Get treatment variant without tracking exposure.

```liquid
{{ 'experiment_name' | absmartly_peek }}
```

**Returns:** Integer variant number

#### `absmartly_variable`

Get variable value and track exposure.

```liquid
{{ 'variable_key' | absmartly_variable: default_value }}
```

**Returns:** Variable value or default

#### `absmartly_peek_variable`

Get variable value without tracking exposure.

```liquid
{{ 'variable_key' | absmartly_peek_variable: default_value }}
```

**Returns:** Variable value or default

#### `absmartly_custom_field`

Get custom field value for an experiment.

```liquid
{{ 'experiment_name' | absmartly_custom_field: 'field_name' }}
```

**Returns:** Parsed field value

#### `absmartly_track`

Track goal achievement with properties.

```liquid
{{ 'goal_name' | absmartly_track: property1: value1, property2: value2 }}
```

**Returns:** Empty string

### Tags

#### `{% absmartly_treatment %}`

Block tag for treatment with local variant variable.

```liquid
{% absmartly_treatment 'experiment_name' %}
  <!-- variant variable available here -->
  {% if variant == 0 %}
    <p>Control</p>
  {% elsif variant == 1 %}
    <p>Treatment</p>
  {% endif %}
{% endabsmartly_treatment %}
```

#### `{% absmartly_track %}`

Tag for tracking goals with properties.

```liquid
{% absmartly_track 'goal_name', key1: value1, key2: value2 %}
```

### Drop Object

The `absmartly` drop object is available in templates and provides access to the context:

#### Properties

```liquid
{% if absmartly.ready %}
  <!-- Context is ready -->
{% endif %}

{% if absmartly.failed %}
  <!-- Context failed to load -->
{% endif %}

<!-- List all experiments -->
{% for exp in absmartly.experiments %}
  <li>{{ exp }}</li>
{% endfor %}

<!-- Pending event count -->
<p>Pending: {{ absmartly.pending }}</p>
```

#### Methods

```liquid
<!-- Get treatment -->
{{ absmartly.treatment('exp_test') }}

<!-- Peek treatment -->
{{ absmartly.peek('exp_test') }}

<!-- Get variable -->
{{ absmartly.variable('button_color', 'blue') }}

<!-- Track goal -->
{{ absmartly.track('purchase', amount: 99.99) }}
```

## Common Use Cases

### Product Page Layout Test

```liquid
{% absmartly_treatment 'exp_product_layout' %}
  {% if variant == 0 %}
    {% render 'product-layout-traditional' %}
  {% elsif variant == 1 %}
    {% render 'product-layout-modern' %}
  {% endif %}
{% endabsmartly_treatment %}
```

### Free Shipping Threshold

```liquid
{% assign threshold = 'free_shipping_threshold' | absmartly_variable: 50 %}
{% assign threshold_cents = threshold | times: 100 %}

{% if cart.total_price >= threshold_cents %}
  <div class="banner-success">You qualify for FREE SHIPPING!</div>
{% else %}
  {% assign remaining = threshold_cents | minus: cart.total_price | money %}
  <div class="banner-info">Add {{ remaining }} more for free shipping</div>
{% endif %}
```

### Button Color Test

```liquid
{% assign button_color = 'checkout_button_color' | absmartly_variable: 'blue' %}
<button class="btn btn-{{ button_color }}">Checkout</button>
```

### Feature Flag

```liquid
{% assign show_new_search = 'feature_new_search' | absmartly_treatment %}

{% if show_new_search == 1 %}
  {% render 'search-v2' %}
{% else %}
  {% render 'search-v1' %}
{% endif %}
```

### Pricing Test with Conversion Tracking

```liquid
{% assign price_variant = 'exp_pricing' | absmartly_treatment %}

{% if price_variant == 0 %}
  {% assign discount = 10 %}
{% elsif price_variant == 1 %}
  {% assign discount = 15 %}
{% elsif price_variant == 2 %}
  {% assign discount = 20 %}
{% endif %}

<p>Save {{ discount }}% today!</p>

<!-- Track conversion on purchase -->
{% if order %}
  {{ 'purchase' | absmartly_track: amount: order.total_price, discount: discount }}
{% endif %}
```

## Advanced

### Publishing Pending Data

Ensure all events are published before proceeding:

```ruby
# In controller (after template render)
@context.publish
```

### Finalizing Context

Finalize the context to publish events and seal it:

```ruby
# In after_action or ensure block
@context.close
```

### Refreshing Context

For long-running contexts, refresh experiment data:

```ruby
# Auto-refresh every 4 hours
context = sdk.create_context(
  units: { session_id: session[:id] },
  refresh_period: 4 * 60 * 60 * 1000
)

# Or refresh manually
context.refresh
```

### Setting Attributes

Add metadata for audience targeting:

```ruby
context.attributes({
  user_agent: request.user_agent,
  customer_age: 'new_customer',
  account_type: 'premium'
})
```

### Overriding Treatments

Force specific variants during development:

```ruby
# In development/staging
context.override('exp_test', 1)

context.overrides({
  'exp_test' => 1,
  'exp_another' => 0
})
```

### Custom Event Logger

Monitor SDK events:

```ruby
event_logger = ->(context, event_name, data) {
  case event_name
  when 'exposure'
    Rails.logger.info "ABsmartly exposure: #{data[:name]}"
  when 'goal'
    Rails.logger.info "ABsmartly goal: #{data[:name]}"
  when 'error'
    Rails.logger.error "ABsmartly error: #{data}"
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

**Event Types:**

| Event | When | Data |
| :--- | :--- | :--- |
| `ready` | Context turns ready | Context initialization data |
| `refresh` | `refresh()` succeeds | Refreshed context data |
| `publish` | `publish()` succeeds | Published events |
| `exposure` | `treatment()` first exposure | Exposure data |
| `goal` | `track()` succeeds | Goal data |
| `close` | `close()` succeeds | undefined |
| `error` | Error occurs | Error object |

### Caching Context Data

Cache context data for improved performance:

```ruby
# With Rails cache
cache_key = "absmartly:#{session[:id]}"
data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
  sdk.get_client.get_context(units: { session_id: session[:id] })
end

context = sdk.create_context_with(
  { units: { session_id: session[:id] } },
  data
)
```

## Error Handling

### In Liquid Templates

Always check if context is ready:

```liquid
{% if absmartly.ready %}
  {% assign variant = 'exp_test' | absmartly_treatment %}
{% else %}
  <!-- Fallback to default -->
  {% assign variant = 0 %}
{% endif %}
```

### In Ruby Code

Handle context errors:

```ruby
begin
  context = sdk.create_context(units: { session_id: session[:id] })
  context.ready
rescue ABSmartly::ContextNotReadyError
  # Context not ready, use fallback
  variant = 0
rescue ABSmartly::HTTPError => e
  # HTTP error, log and fallback
  Rails.logger.error "ABsmartly HTTP error: #{e.message}"
  variant = 0
end
```

## Performance Tips

1. **Pre-fetch Context Data**: Fetch data server-side before rendering templates
2. **Cache Context Data**: Use Redis or Rails cache for context data (5-10 minute TTL)
3. **Batch Event Publishing**: Set `publish_delay` to batch events
4. **Minimize Liquid Logic**: Pre-calculate variants in controller when possible
5. **Use Peek Sparingly**: Only use peek when you truly don't want exposure tracking

## Best Practices

1. **Initialize Once Per Request**: Create context in `before_action` or controller
2. **Use Consistent Units**: Same `session_id`/`customer_id` throughout request
3. **Handle Not Ready State**: Always check `absmartly.ready` in templates
4. **Track Conversions**: Use `absmartly_track` on important user actions
5. **Finalize on Exit**: Call `context.close` in `after_action`
6. **Monitor Errors**: Log all ABsmartly errors for debugging
7. **Test Fallbacks**: Ensure app works when ABsmartly is unavailable

## Shopify Integration Example

### Complete Controller Setup

```ruby
class ApplicationController < ActionController::Base
  before_action :init_absmartly
  after_action :close_absmartly

  private

  def init_absmartly
    # Initialize SDK (once per app)
    $absmartly_sdk ||= ABSmartly::SDK.new(
      endpoint: ENV['ABSMARTLY_ENDPOINT'],
      api_key: ENV['ABSMARTLY_API_KEY'],
      application: 'my-shopify-store',
      environment: Rails.env
    )

    # Create context for this request
    @context = $absmartly_sdk.create_context(
      units: {
        session_id: session[:id],
        customer_id: current_customer&.id
      },
      publish_delay: 100
    )

    @context.ready

    # Set attributes
    @context.attributes({
      user_agent: request.user_agent,
      customer_logged_in: current_customer.present?
    })

    # Make available to Liquid
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

### Shopify Theme Template

```liquid
<!-- layout/theme.liquid -->
<!DOCTYPE html>
<html>
<head>
  <title>{{ page_title }}</title>
</head>
<body>
  {% if absmartly.ready %}
    <!-- A/B test header color -->
    {% assign header_color = 'header_color' | absmartly_variable: 'blue' %}
    <header style="background: {{ header_color }}">
      {% render 'header' %}
    </header>
  {% else %}
    <!-- Fallback header -->
    <header style="background: blue">
      {% render 'header' %}
    </header>
  {% endif %}

  {{ content_for_layout }}

  <footer>
    {% render 'footer' %}
  </footer>
</body>
</html>
```

## Jekyll Integration Example

### Jekyll Plugin Setup

```ruby
# _plugins/absmartly.rb
require 'absmartly/liquid'

Jekyll::Hooks.register :site, :pre_render do |site|
  # Initialize SDK
  sdk = ABSmartly::SDK.new(
    endpoint: ENV['ABSMARTLY_ENDPOINT'],
    api_key: ENV['ABSMARTLY_API_KEY'],
    application: 'jekyll-site',
    environment: ENV['JEKYLL_ENV'] || 'development'
  )

  # Create context (static site uses fixed unit)
  context = sdk.create_context(
    units: { site_id: site.config['url'] }
  )
  context.ready

  # Make available to all templates
  drop = ABSmartly::Liquid::Drop.new(context)
  site.config['absmartly'] = drop
end
```

### Jekyll Template Usage

```liquid
<!-- _layouts/default.html -->
{% assign hero_variant = 'exp_homepage_hero' | absmartly_treatment %}

{% if hero_variant == 0 %}
  {% include hero-v1.html %}
{% elsif hero_variant == 1 %}
  {% include hero-v2.html %}
{% endif %}
```

## Module Naming Note

This SDK uses the namespaced module name `ABsmartly::Liquid` to avoid conflicts with the standalone Ruby SDK (`Absmartly` module). This allows you to use both SDKs in the same application if needed.

```ruby
# Liquid SDK (this package)
require 'absmartly/liquid'
sdk = ABSmartly::SDK.new(...)

# Ruby SDK (separate package)
require 'absmartly'
sdk = Absmartly::SDK.new(...)
```

## Configuration

### Error Handling Modes

The SDK supports two error handling modes:

#### Graceful Mode (Default - Production)

Errors are logged but don't crash page rendering:

```ruby
ABsmartly::Liquid.strict_mode = false  # Default
```

In this mode:
- Missing context returns control variant (0) and logs warning
- SDK errors return safe defaults and log error
- Pages always render successfully
- Tracking events that fail are logged

**Use for: Production environments**

#### Strict Mode (Development/Staging)

Errors raise exceptions immediately:

```ruby
ABsmartly::Liquid.strict_mode = true
```

In this mode:
- Missing context raises exception
- SDK errors propagate exception
- Pages crash if SDK misconfigured
- Helps catch configuration issues early

**Use for: Development and staging environments**

### Logging Configuration

Configure the SDK logger:

```ruby
# Use your application's logger
ABsmartly::Liquid.logger = Rails.logger

# Or custom logger
ABsmartly::Liquid.logger = Logger.new('log/absmartly.log')
ABsmartly::Liquid.logger.level = Logger::WARN

# Disable logging
ABsmartly::Liquid.logger = Logger.new('/dev/null')
```

**Important log messages to monitor:**
- `"ABsmartly context missing"` - indicates Drop not injected into template
- `"ABsmartly context not ready"` - indicates SDK initialization failure
- `"event dropped"` - indicates lost tracking data

## Known Limitations

### Nested Treatment Blocks

When nesting `{% absmartly_treatment %}` blocks, be aware that both blocks use the same `variant` variable. The inner block will overwrite the outer variant:

```liquid
{% absmartly_treatment 'exp_outer' %}
  Outer variant: {{ variant }}  <!-- This works -->

  {% absmartly_treatment 'exp_inner' %}
    Inner variant: {{ variant }}  <!-- This works -->
  {% endabsmartly_treatment %}

  Outer variant again: {{ variant }}  <!-- This shows INNER variant! -->
{% endabsmartly_treatment %}
```

**Workaround:** Assign variant to a different variable name:

```liquid
{% absmartly_treatment 'exp_outer' %}
  {% assign outer_variant = variant %}

  {% absmartly_treatment 'exp_inner' %}
    {% assign inner_variant = variant %}
  {% endabsmartly_treatment %}

  <!-- Now both variants accessible -->
  Outer: {{ outer_variant }}, Inner: {{ inner_variant }}
{% endabsmartly_treatment %}
```

### Experiment Name Restrictions

Experiment names, goal names, and variable keys may contain:
- Letters (a-z, A-Z)
- Numbers (0-9)
- Underscores (_)
- Hyphens (-)
- Dots (.)

Special characters beyond these may cause parsing errors.

## Security

**CRITICAL:** Always review [SECURITY.md](./SECURITY.md) before deploying to production.

Key security requirements:
- Never expose API keys client-side
- Always use `| json` filter when interpolating into `<script>` tags
- Validate user-controlled data before using in experiment/goal names
- Use Content Security Policy headers
- Never reuse contexts across requests (thread safety)

See [SECURITY.md](./SECURITY.md) for complete security guidelines.

## Troubleshooting

### Context Not Ready

**Problem:** Templates show default variant even though experiment is running.

**Solution:** Ensure context is ready before rendering:

```ruby
@context.ready  # Blocks until ready
```

### Events Not Tracking

**Problem:** No exposures or goals appearing in dashboard.

**Solution:** Enable debug logging:

```ruby
event_logger = ->(ctx, event, data) {
  Rails.logger.debug "ABsmartly: #{event} - #{data.inspect}"
}
```

### Variant Mismatch

**Problem:** User sees different variants on page reload.

**Solution:** Use consistent session ID:

```ruby
session[:id] ||= SecureRandom.uuid
```

### Performance Issues

**Problem:** Template rendering is slow.

**Solution:** Pre-fetch and cache context data:

```ruby
data = Rails.cache.fetch("absmartly:#{session[:id]}", expires_in: 5.minutes) do
  sdk.get_client.get_context(units: { session_id: session[:id] })
end
```

## About A/B Smartly

**A/B Smartly** is the leading provider of state-of-the-art, on-premises, full-stack experimentation platforms for engineering and product teams that want to confidently deploy features as fast as they can develop them.
A/B Smartly's real-time analytics helps engineering and product teams ensure that new features will improve the customer experience without breaking or degrading performance and/or business metrics.

### Have a look at our growing list of clients and SDKs:

- [JavaScript SDK](https://www.github.com/absmartly/javascript-sdk)
- [React SDK](https://www.github.com/absmartly/react-sdk)
- [Vue2 SDK](https://www.github.com/absmartly/vue2-sdk)
- [Vue3 SDK](https://www.github.com/absmartly/vue3-sdk)
- [Java SDK](https://www.github.com/absmartly/java-sdk)
- [Android SDK](https://www.github.com/absmartly/android-sdk)
- [Swift SDK](https://www.github.com/absmartly/swift-sdk)
- [Dart SDK](https://www.github.com/absmartly/dart-sdk)
- [Flutter SDK](https://www.github.com/absmartly/flutter-sdk)
- [PHP SDK](https://www.github.com/absmartly/php-sdk)
- [Python3 SDK](https://www.github.com/absmartly/python3-sdk)
- [Go SDK](https://www.github.com/absmartly/go-sdk)
- [Ruby SDK](https://www.github.com/absmartly/ruby-sdk)
- [.NET SDK](https://www.github.com/absmartly/dotnet-sdk)
- [Rust SDK](https://www.github.com/absmartly/rust-sdk)
- [Liquid SDK](https://www.github.com/absmartly/liquid-sdk) (this package)

## Documentation

- [Full Documentation](https://docs.absmartly.com/)
- [API Reference](./API.md)
- [Quick Start Guide](./QUICKSTART.md)
- [Implementation Details](./IMPLEMENTATION.md)

## License

Apache License 2.0 - see [LICENSE](./LICENSE) for details.
