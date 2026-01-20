# ABsmartly Liquid SDK - Quick Start Guide

Get started with A/B testing in your Shopify store in 5 minutes.

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

### For Shopify Themes

1. Copy the SDK files to your theme
2. Add initialization snippet to your layout
3. Start using A/B tests in your templates

## Step 1: Initialize SDK

In your Ruby controller or initializer:

```ruby
# config/initializers/absmartly.rb
require 'absmartly/liquid'

$absmartly_sdk = ABSmartly::SDK.new(
  endpoint: ENV['ABSMARTLY_ENDPOINT'],
  api_key: ENV['ABSMARTLY_API_KEY'],
  application: 'my-shopify-store',
  environment: Rails.env
)
```

## Step 2: Create Context (Server-Side)

In your controller:

```ruby
class ApplicationController < ActionController::Base
  before_action :init_absmartly

  private

  def init_absmartly
    @absmartly = $absmartly_sdk.create_context(
      units: {
        session_id: session[:id],
        customer_id: current_customer&.id
      }
    )
    @absmartly.ready

    # Make available to Liquid
    @absmartly_drop = ABSmartly::Liquid::Drop.new(@absmartly)
  end
end
```

In your view:

```ruby
render 'template', assigns: { 'absmartly' => @absmartly_drop }
```

## Step 3: Use in Liquid Templates

### A/B Test Button Color

```liquid
{% assign variant = 'exp_button_color' | absmartly_treatment %}

{% if variant == 0 %}
  <button class="btn-blue">Buy Now</button>
{% elsif variant == 1 %}
  <button class="btn-red">Buy Now</button>
{% endif %}
```

### A/B Test with Variables

```liquid
{% assign button_text = 'checkout_button_text' | absmartly_variable: 'Checkout' %}
{% assign button_color = 'checkout_button_color' | absmartly_variable: 'blue' %}

<a href="/checkout" class="btn btn-{{ button_color }}">
  {{ button_text }}
</a>
```

### Track Conversions

```liquid
<!-- On purchase -->
{{ 'purchase' | absmartly_track: amount: order.total_price, items: order.line_items.size }}

<!-- On add to cart -->
<button onclick="window.absmartly.track('add_to_cart', { product_id: {{ product.id }}, price: {{ product.price }} })">
  Add to Cart
</button>
```

## Step 4: Create Experiments in ABsmartly

1. Log into ABsmartly web console
2. Create new experiment: "exp_button_color"
3. Add variants:
   - Variant 0: Control (blue button)
   - Variant 1: Treatment (red button)
4. Set traffic allocation (e.g., 50/50 split)
5. Start experiment

## Step 5: View Results

1. Liquid automatically tracks exposures when `absmartly_treatment` is called
2. Track goals with `absmartly_track` filter
3. View results in ABsmartly dashboard

## Common Use Cases

### Product Page Layout Test

```liquid
{% assign layout_variant = 'exp_product_layout' | absmartly_treatment %}

{% if layout_variant == 0 %}
  {% render 'product-layout-traditional' %}
{% elsif layout_variant == 1 %}
  {% render 'product-layout-modern' %}
{% endif %}
```

### Free Shipping Threshold

```liquid
{% assign threshold = 'free_shipping_threshold' | absmartly_variable: 50 %}
{% assign threshold_cents = threshold | times: 100 %}

{% if cart.total_price >= threshold_cents %}
  <div class="banner-success">You qualify for FREE SHIPPING!</div>
{% else %}
  {% assign remaining = threshold_cents | minus: cart.total_price | money %}
  <div>Add {{ remaining }} more for free shipping</div>
{% endif %}
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

## Performance Tips

### 1. Cache Context Data

```ruby
# In controller
cache_key = "absmartly:#{session[:id]}"
data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
  $absmartly_sdk.get_client.get_context(units: { session_id: session[:id] })
end

@absmartly = $absmartly_sdk.create_context_with(
  { units: { session_id: session[:id] } },
  data
)
```

### 2. Pre-Calculate Variants

```ruby
# In controller (before rendering)
@button_variant = @absmartly.treatment('exp_button_color')
@layout_variant = @absmartly.treatment('exp_layout')

# In template
{% if button_variant == 1 %}
  <button class="red">Buy Now</button>
{% endif %}
```

### 3. Batch Event Publishing

```ruby
# In controller
context_config = ABSmartly::ContextConfig.new
context_config.publish_delay = 100  # Batch events for 100ms
```

## Troubleshooting

### Context Not Ready

```liquid
{% if absmartly.ready %}
  {% assign variant = 'exp_test' | absmartly_treatment %}
{% else %}
  <!-- Fallback -->
  {% assign variant = 0 %}
{% endif %}
```

### Events Not Tracking

Enable debug logging:

```ruby
$absmartly_sdk = ABSmartly::SDK.new(
  endpoint: ENV['ABSMARTLY_ENDPOINT'],
  api_key: ENV['ABSMARTLY_API_KEY'],
  application: 'my-store',
  environment: Rails.env,
  event_logger: ->(ctx, event, data) { Rails.logger.debug "ABsmartly: #{event} - #{data}" }
)
```

### Variant Mismatch

Ensure same session ID:

```ruby
# Use same session ID throughout request
session_id = session[:id] || SecureRandom.uuid
session[:id] = session_id

@absmartly = $absmartly_sdk.create_context(units: { session_id: session_id })
```

## Next Steps

- Read the [full documentation](./README.md)
- Check the [API reference](./API.md)
- Explore [Shopify theme examples](./examples/shopify-theme/)
- Learn about [implementation details](./IMPLEMENTATION.md)

## Support

- [ABsmartly Documentation](https://docs.absmartly.com)
- [Shopify Liquid Documentation](https://shopify.github.io/liquid/)
- [GitHub Issues](https://github.com/absmartly/liquid-sdk/issues)

## License

Apache License 2.0
