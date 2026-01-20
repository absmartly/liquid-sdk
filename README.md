# ABsmartly SDK for Shopify Liquid

A/B Smartly SDK for Shopify Liquid templating language with server-side rendering support.

## Overview

This SDK enables A/B testing in Shopify stores using Liquid templates. It provides Liquid filters, tags, and drops (objects) that integrate with ABsmartly's experimentation platform.

**Architecture:**
- Ruby backend SDK (handles HTTP, variant assignment, hashing)
- Liquid filters and tags for template integration
- Server-side context initialization and caching
- Shopify theme integration

## Compatibility

- Shopify Liquid templates
- Ruby 2.7+ (Shopify backend)
- Works with Shopify themes and apps

## Installation

### For Shopify Themes

1. Add the ABsmartly Liquid SDK files to your theme:

```
assets/
  absmartly.js        # Client-side tracking (optional)
snippets/
  absmartly-init.liquid   # Initialization snippet
  absmartly-tracking.liquid  # Tracking snippet
```

2. Add initialization to your `theme.liquid`:

```liquid
{% render 'absmartly-init',
  session_id: customer.id | default: request.cookie.session_id,
  customer_id: customer.id
%}
```

### For Shopify Apps

Add to your Gemfile:

```ruby
gem 'absmartly-liquid-sdk'
```

Then run:

```bash
bundle install
```

## Quick Start

### 1. Initialize Context (Server-Side)

In your Shopify app controller or theme:

```ruby
# Initialize SDK
sdk = ABSmartly::SDK.new(
  endpoint: 'https://your-endpoint.absmartly.io/v1',
  api_key: ENV['ABSMARTLY_API_KEY'],
  application: 'shopify-store',
  environment: 'production'
)

# Create context
@absmartly_context = sdk.create_context(
  units: {
    session_id: session[:id],
    customer_id: current_customer&.id
  }
)

# Wait for ready
@absmartly_context.ready

# Make context available to Liquid
@absmartly_data = {
  'context_data' => @absmartly_context.data.to_json,
  'units' => @absmartly_context.get_units
}
```

### 2. Use in Liquid Templates

#### Treatment Assignment

```liquid
{% assign variant = 'exp_button_color' | absmartly_treatment %}

{% if variant == 0 %}
  <button class="btn-blue">Buy Now</button>
{% elsif variant == 1 %}
  <button class="btn-red">Buy Now</button>
{% endif %}
```

#### Variable Access

```liquid
{% assign button_text = 'button_text' | absmartly_variable: 'Buy Now' %}
<button>{{ button_text }}</button>
```

#### Peek (Without Tracking)

```liquid
{% assign variant = 'exp_button_color' | absmartly_peek %}
```

#### Goal Tracking

```liquid
{% absmartly_track 'add_to_cart', amount: product.price, quantity: 1 %}
```

Or use the filter:

```liquid
{{ 'purchase' | absmartly_track: amount: order.total_price }}
```

### 3. Client-Side Tracking (Optional)

For tracking after page load:

```liquid
<script>
  // ABsmartly context initialized server-side
  window.absmartly.track('button_click', {
    variant: {{ variant }},
    product_id: {{ product.id }}
  });
</script>
```

## Liquid Filters

### `absmartly_treatment`

Get variant and track exposure.

```liquid
{% assign variant = 'exp_test' | absmartly_treatment %}
```

**Returns:** Variant number (0, 1, 2, ...)

**Side effect:** Tracks exposure event

### `absmartly_peek`

Get variant without tracking exposure.

```liquid
{% assign variant = 'exp_test' | absmartly_peek %}
```

**Returns:** Variant number (0, 1, 2, ...)

**Side effect:** None

### `absmartly_variable`

Get variable value and track exposure.

```liquid
{% assign value = 'button_color' | absmartly_variable: 'blue' %}
```

**Parameters:**
- First argument (pipe input): Variable key
- Second argument: Default value

**Returns:** Variable value or default

**Side effect:** Tracks exposure event

### `absmartly_peek_variable`

Get variable value without tracking exposure.

```liquid
{% assign value = 'button_color' | absmartly_peek_variable: 'blue' %}
```

**Returns:** Variable value or default

**Side effect:** None

### `absmartly_track`

Track goal achievement.

```liquid
{{ 'purchase' | absmartly_track: amount: order.total_price, items: order.line_items.size }}
```

**Parameters:**
- First argument (pipe input): Goal name
- Named parameters: Goal properties (must be numeric)

**Returns:** Empty string

**Side effect:** Queues goal event for publishing

### `absmartly_custom_field`

Get custom field value.

```liquid
{% assign metadata = 'exp_test' | absmartly_custom_field: 'metadata' %}
```

**Returns:** Parsed field value based on type

## Liquid Tags

### `absmartly_treatment`

Block tag for treatment assignment.

```liquid
{% absmartly_treatment 'exp_button_color' %}
  {% if variant == 0 %}
    <button class="btn-blue">Control</button>
  {% elsif variant == 1 %}
    <button class="btn-red">Treatment</button>
  {% endif %}
{% endabsmartly_treatment %}
```

Inside the block, `variant` variable is available.

### `absmartly_track`

Track goal with properties.

```liquid
{% absmartly_track 'purchase', amount: order.total_price, items: order.line_items.size %}
```

## Liquid Drops (Objects)

ABsmartly context is available as `absmartly` object in Liquid:

```liquid
{{ absmartly.experiments }}  <!-- Array of experiment names -->
{{ absmartly.pending }}      <!-- Number of pending events -->
{{ absmartly.ready }}        <!-- true/false -->
```

### Properties

- `ready` (boolean) - Whether context is ready
- `failed` (boolean) - Whether context failed to load
- `finalized` (boolean) - Whether context is finalized
- `experiments` (array) - List of experiment names
- `pending` (number) - Count of pending events

### Methods

```liquid
{{ absmartly.treatment('exp_test') }}
{{ absmartly.peek('exp_test') }}
{{ absmartly.variable('button_color', 'blue') }}
{{ absmartly.peek_variable('button_color', 'blue') }}
{{ absmartly.custom_field('exp_test', 'metadata') }}
{{ absmartly.track('goal_name', properties) }}
```

## Server-Side Integration

### Shopify App Example

```ruby
class ProductsController < ApplicationController
  before_action :init_absmartly

  def show
    @product = Product.find(params[:id])

    # Get variant for this user
    variant = @absmartly.treatment('exp_product_layout')

    # Pass to view
    @layout_variant = variant

    # Data for Liquid
    @absmartly_liquid = ABSmartly::LiquidDrop.new(@absmartly)
  end

  private

  def init_absmartly
    @absmartly = $absmartly_sdk.create_context(
      units: {
        session_id: session[:id],
        customer_id: current_customer&.id
      }
    )
    @absmartly.ready
  end
end
```

### Theme Liquid Integration

```liquid
<!-- theme.liquid -->
{% capture session_id %}{{ request.cookie['_shopify_s'] }}{% endcapture %}

{% render 'absmartly-init',
  endpoint: 'https://your-endpoint.absmartly.io/v1',
  api_key: 'your-api-key',
  session_id: session_id,
  customer_id: customer.id
%}

<!-- product.liquid -->
{% assign layout_variant = 'exp_product_layout' | absmartly_treatment %}

{% if layout_variant == 0 %}
  {% render 'product-layout-control' %}
{% elsif layout_variant == 1 %}
  {% render 'product-layout-treatment' %}
{% endif %}
```

## Advanced Usage

### Pre-fetching Context Data

For better performance, pre-fetch context data server-side:

```ruby
# In controller
data = sdk.get_client.get_context(units: { session_id: session[:id] })

# Create context with data (no HTTP call)
@absmartly = sdk.create_context_with(
  { units: { session_id: session[:id] } },
  data
)

# Pass to Liquid
assigns['absmartly'] = ABSmartly::LiquidDrop.new(@absmartly)
```

### Caching Context Data

```ruby
# Cache context data for session
cache_key = "absmartly:#{session[:id]}"
data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
  sdk.get_client.get_context(units: { session_id: session[:id] })
end

@absmartly = sdk.create_context_with({ units: { session_id: session[:id] } }, data)
```

### Custom Event Logger

```ruby
class ShopifyEventLogger
  def handle_event(context, event_name, data)
    case event_name
    when 'exposure'
      # Log to Shopify analytics
      Analytics.track('absmartly_exposure', data)
    when 'goal'
      # Log to your tracking system
      Tracking.event('absmartly_goal', data)
    when 'error'
      # Log errors
      Rails.logger.error("ABsmartly error: #{data}")
    end
  end
end

sdk = ABSmartly::SDK.new(
  endpoint: ENV['ABSMARTLY_ENDPOINT'],
  api_key: ENV['ABSMARTLY_API_KEY'],
  application: 'shopify-store',
  environment: Rails.env,
  event_logger: ShopifyEventLogger.new
)
```

### Publishing Events

Events are automatically published, but you can manually publish:

```ruby
# In controller after action
@absmartly.publish
```

Or finalize on session end:

```ruby
# In ApplicationController
after_action :finalize_absmartly

def finalize_absmartly
  @absmartly&.finalize
end
```

## Examples

### Product Page A/B Test

```liquid
<!-- product.liquid -->
{% assign variant = 'exp_product_images' | absmartly_treatment %}

{% if variant == 0 %}
  <!-- Control: Single image -->
  <img src="{{ product.featured_image | img_url: 'large' }}" alt="{{ product.title }}">
{% elsif variant == 1 %}
  <!-- Treatment: Image gallery -->
  <div class="product-gallery">
    {% for image in product.images %}
      <img src="{{ image | img_url: 'medium' }}" alt="{{ product.title }}">
    {% endfor %}
  </div>
{% endif %}

<!-- Track add to cart -->
<form action="/cart/add" method="post">
  <button type="submit" onclick="absmartly.track('add_to_cart', { product_id: {{ product.id }}, price: {{ product.price }} })">
    Add to Cart
  </button>
</form>
```

### Checkout Button Text

```liquid
{% assign button_text = 'checkout_button_text' | absmartly_variable: 'Checkout' %}
{% assign button_color = 'checkout_button_color' | absmartly_variable: 'blue' %}

<a href="/checkout" class="btn-{{ button_color }}">
  {{ button_text }}
</a>
```

### Free Shipping Threshold

```liquid
{% assign free_shipping_threshold = 'free_shipping_threshold' | absmartly_variable: 50 %}

{% if cart.total_price >= free_shipping_threshold %}
  <div class="free-shipping-banner">
    🎉 You qualify for free shipping!
  </div>
{% else %}
  {% assign remaining = free_shipping_threshold | minus: cart.total_price %}
  <div class="free-shipping-progress">
    Add ${{ remaining }} more for free shipping
  </div>
{% endif %}
```

### Conversion Tracking

```liquid
<!-- Thank you page (checkout complete) -->
{% if first_time_accessed %}
  {% absmartly_track 'purchase',
    amount: order.total_price,
    items: order.line_items.size,
    revenue: order.subtotal_price
  %}
{% endif %}
```

### Feature Flags

```liquid
{% assign show_new_feature = 'feature_new_search' | absmartly_treatment %}

{% if show_new_feature == 1 %}
  {% render 'search-v2' %}
{% else %}
  {% render 'search-v1' %}
{% endif %}
```

## Testing

### Unit Tests

```ruby
require 'minitest/autorun'
require 'absmartly/liquid'

class ABSmartlyLiquidTest < Minitest::Test
  def setup
    @sdk = ABSmartly::SDK.new(
      endpoint: 'https://sandbox.absmartly.io/v1',
      api_key: 'test-key',
      application: 'test',
      environment: 'test'
    )

    @context = @sdk.create_context(units: { session_id: 'test123' })
    @context.ready
  end

  def test_treatment_filter
    template = Liquid::Template.parse("{{ 'exp_test' | absmartly_treatment }}")
    output = template.render('absmartly' => ABSmartly::LiquidDrop.new(@context))

    assert_match /^[0-9]+$/, output
  end

  def test_variable_filter
    template = Liquid::Template.parse("{{ 'button_color' | absmartly_variable: 'blue' }}")
    output = template.render('absmartly' => ABSmartly::LiquidDrop.new(@context))

    assert_includes ['blue', 'red', 'green'], output
  end
end
```

### Integration Tests

See `test/integration_test.rb` for full integration tests.

## Performance Considerations

### Caching

- Cache context data per session (5-10 minutes)
- Use Redis for distributed caching
- Pre-fetch data server-side to avoid blocking Liquid rendering

### Event Publishing

- Events are batched and published asynchronously
- Configure `publish_delay` to batch more events
- Use background jobs for publishing on high-traffic stores

### Liquid Rendering

- Minimize A/B test logic in templates
- Pre-calculate variants server-side when possible
- Use fragment caching for expensive A/B test blocks

## Troubleshooting

### Context Not Ready

If `absmartly.ready` is false:

```liquid
{% if absmartly.ready %}
  {% assign variant = 'exp_test' | absmartly_treatment %}
{% else %}
  <!-- Fallback UI -->
{% endif %}
```

### Events Not Publishing

Check event logger configuration and network connectivity:

```ruby
# Enable debug logging
sdk = ABSmartly::SDK.new(
  endpoint: ENV['ABSMARTLY_ENDPOINT'],
  api_key: ENV['ABSMARTLY_API_KEY'],
  application: 'shopify-store',
  environment: Rails.env,
  event_logger: ->(ctx, event, data) { Rails.logger.debug "ABsmartly: #{event} - #{data}" }
)
```

### Variant Mismatch

Ensure units are consistent:

```ruby
# Use same session ID everywhere
session_id = session[:id] || SecureRandom.uuid
session[:id] = session_id

@absmartly = sdk.create_context(units: { session_id: session_id })
```

## API Reference

See [API.md](./API.md) for complete API documentation.

## Best Practices

1. **Initialize once per request** - Create context in controller/before_action
2. **Use consistent units** - Same session_id/customer_id throughout request
3. **Cache context data** - Reduce HTTP calls to ABsmartly
4. **Track conversions** - Use `absmartly_track` on important actions
5. **Test fallbacks** - Handle context not ready gracefully
6. **Monitor performance** - Log slow requests, optimize caching

## Examples Repository

See [examples/](./examples/) for complete Shopify theme examples:
- Product page A/B tests
- Checkout flow optimization
- Homepage layout variations
- Feature flags
- Conversion tracking

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

Apache License 2.0

## About ABsmartly

**ABsmartly** is the leading provider of state-of-the-art, on-premises, full-stack experimentation platforms for engineering and product teams that want to confidently deploy features as fast as they can develop them.

### Links

- [Documentation](https://docs.absmartly.com)
- [JavaScript SDK](https://github.com/absmartly/javascript-sdk)
- [Python SDK](https://github.com/absmartly/python3-sdk)
- [Ruby SDK](https://github.com/absmartly/ruby-sdk)
- [Java SDK](https://github.com/absmartly/java-sdk)
