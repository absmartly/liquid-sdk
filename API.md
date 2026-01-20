## API Reference

Complete API documentation for ABsmartly Liquid SDK.

## Table of Contents

1. [Liquid Filters](#liquid-filters)
2. [Liquid Tags](#liquid-tags)
3. [Liquid Drops](#liquid-drops)
4. [Ruby API](#ruby-api)
5. [Configuration](#configuration)

---

## Liquid Filters

### `absmartly_treatment`

Get treatment variant and track exposure.

**Syntax:**
```liquid
{{ 'experiment_name' | absmartly_treatment }}
```

**Parameters:**
- `experiment_name` (string): Name of the experiment

**Returns:** Integer variant number (0, 1, 2, ...)

**Side Effects:** Creates exposure event

**Example:**
```liquid
{% assign variant = 'exp_button_color' | absmartly_treatment %}
{% if variant == 0 %}
  <button class="blue">Buy Now</button>
{% elsif variant == 1 %}
  <button class="red">Buy Now</button>
{% endif %}
```

---

### `absmartly_peek`

Get treatment variant without tracking exposure.

**Syntax:**
```liquid
{{ 'experiment_name' | absmartly_peek }}
```

**Parameters:**
- `experiment_name` (string): Name of the experiment

**Returns:** Integer variant number (0, 1, 2, ...)

**Side Effects:** None

**Example:**
```liquid
{% assign variant = 'exp_feature' | absmartly_peek %}
```

---

### `absmartly_variable`

Get variable value and track exposure.

**Syntax:**
```liquid
{{ 'variable_key' | absmartly_variable: default_value }}
```

**Parameters:**
- `variable_key` (string): Variable key
- `default_value` (any): Default value if variable not found

**Returns:** Variable value or default

**Side Effects:** Creates exposure event for experiments with this variable

**Example:**
```liquid
{% assign button_text = 'checkout_button_text' | absmartly_variable: 'Checkout' %}
<button>{{ button_text }}</button>
```

---

### `absmartly_peek_variable`

Get variable value without tracking exposure.

**Syntax:**
```liquid
{{ 'variable_key' | absmartly_peek_variable: default_value }}
```

**Parameters:**
- `variable_key` (string): Variable key
- `default_value` (any): Default value if variable not found

**Returns:** Variable value or default

**Side Effects:** None

**Example:**
```liquid
{% assign color = 'button_color' | absmartly_peek_variable: 'blue' %}
```

---

### `absmartly_custom_field`

Get custom field value for an experiment.

**Syntax:**
```liquid
{{ 'experiment_name' | absmartly_custom_field: 'field_name' }}
```

**Parameters:**
- `experiment_name` (string): Name of the experiment
- `field_name` (string): Name of the custom field

**Returns:** Parsed field value (type depends on field configuration)

**Example:**
```liquid
{% assign metadata = 'exp_test' | absmartly_custom_field: 'metadata' %}
```

---

### `absmartly_track`

Track goal achievement.

**Syntax:**
```liquid
{{ 'goal_name' | absmartly_track: property1: value1, property2: value2 }}
```

**Parameters:**
- `goal_name` (string): Name of the goal
- Named parameters: Goal properties (must be numeric)

**Returns:** Empty string

**Side Effects:** Creates goal event

**Example:**
```liquid
{{ 'purchase' | absmartly_track: amount: order.total_price, items: order.line_items.size }}
```

---

## Liquid Tags

### `absmartly_treatment`

Block tag for treatment with local variant variable.

**Syntax:**
```liquid
{% absmartly_treatment 'experiment_name' %}
  <!-- variant variable available here -->
{% endabsmartly_treatment %}
```

**Parameters:**
- `experiment_name` (string): Name of the experiment

**Local Variables:**
- `variant` (integer): Assigned variant number

**Side Effects:** Creates exposure event

**Example:**
```liquid
{% absmartly_treatment 'exp_layout' %}
  {% if variant == 0 %}
    {% render 'layout-control' %}
  {% elsif variant == 1 %}
    {% render 'layout-treatment' %}
  {% endif %}
{% endabsmartly_treatment %}
```

---

### `absmartly_track`

Tag for tracking goals with properties.

**Syntax:**
```liquid
{% absmartly_track 'goal_name', key1: value1, key2: value2 %}
```

**Parameters:**
- `goal_name` (string): Name of the goal
- Named parameters: Goal properties (must be numeric)

**Side Effects:** Creates goal event

**Example:**
```liquid
{% absmartly_track 'add_to_cart', product_id: product.id, price: product.price %}
```

---

## Liquid Drops

### `absmartly` Drop

Main ABsmartly context object available in Liquid templates.

#### Properties

##### `ready`

**Type:** Boolean

**Description:** Whether context is ready

**Example:**
```liquid
{% if absmartly.ready %}
  <!-- Use A/B tests -->
{% else %}
  <!-- Fallback -->
{% endif %}
```

---

##### `failed`

**Type:** Boolean

**Description:** Whether context failed to load

**Example:**
```liquid
{% if absmartly.failed %}
  <p>A/B testing unavailable</p>
{% endif %}
```

---

##### `finalized`

**Type:** Boolean

**Description:** Whether context is finalized

**Example:**
```liquid
{{ absmartly.finalized }}
```

---

##### `experiments`

**Type:** Array of strings

**Description:** List of all experiment names

**Example:**
```liquid
<ul>
  {% for exp in absmartly.experiments %}
    <li>{{ exp }}</li>
  {% endfor %}
</ul>
```

---

##### `pending`

**Type:** Integer

**Description:** Count of pending events (exposures + goals + attributes)

**Example:**
```liquid
<p>Pending events: {{ absmartly.pending }}</p>
```

---

#### Methods

##### `treatment(experiment_name)`

Get treatment variant and track exposure.

**Parameters:**
- `experiment_name` (string): Experiment name

**Returns:** Integer variant number

**Example:**
```liquid
{{ absmartly.treatment('exp_test') }}
```

---

##### `peek(experiment_name)`

Get treatment variant without tracking exposure.

**Parameters:**
- `experiment_name` (string): Experiment name

**Returns:** Integer variant number

**Example:**
```liquid
{{ absmartly.peek('exp_test') }}
```

---

##### `variable(key, default)`

Get variable value and track exposure.

**Parameters:**
- `key` (string): Variable key
- `default` (any): Default value

**Returns:** Variable value or default

**Example:**
```liquid
{{ absmartly.variable('button_color', 'blue') }}
```

---

##### `peek_variable(key, default)`

Get variable value without tracking exposure.

**Parameters:**
- `key` (string): Variable key
- `default` (any): Default value

**Returns:** Variable value or default

**Example:**
```liquid
{{ absmartly.peek_variable('button_color', 'blue') }}
```

---

##### `custom_field(experiment_name, field_name)`

Get custom field value.

**Parameters:**
- `experiment_name` (string): Experiment name
- `field_name` (string): Field name

**Returns:** Parsed field value

**Example:**
```liquid
{{ absmartly.custom_field('exp_test', 'metadata') }}
```

---

##### `track(goal_name, properties)`

Track goal achievement.

**Parameters:**
- `goal_name` (string): Goal name
- `properties` (hash, optional): Goal properties

**Returns:** nil

**Example:**
```liquid
{{ absmartly.track('purchase', amount: 99.99) }}
```

---

##### `data`

Get raw context data.

**Returns:** Hash of context data

**Example:**
```liquid
{{ absmartly.data }}
```

---

##### `units`

Get all units.

**Returns:** Hash of unit types to identifiers

**Example:**
```liquid
{{ absmartly.units }}
```

---

## Ruby API

### SDK Class

#### `ABSmartly::SDK.new(config)`

Create SDK instance.

**Parameters:**
- `config` (Hash or SDKConfig): Configuration options

**Returns:** SDK instance

**Example:**
```ruby
sdk = ABSmartly::SDK.new(
  endpoint: 'https://your-endpoint.absmartly.io/v1',
  api_key: ENV['ABSMARTLY_API_KEY'],
  application: 'shopify-store',
  environment: 'production'
)
```

---

#### `sdk.create_context(params)`

Create context (async data fetch).

**Parameters:**
- `params` (Hash or ContextConfig): Context parameters
  - `units` (Hash): Unit identifiers
  - `publish_delay` (Integer): Auto-publish delay in ms (-1 to disable)
  - `refresh_period` (Integer): Auto-refresh interval in ms (0 to disable)
  - `event_logger` (Proc): Custom event logger

**Returns:** Context instance

**Example:**
```ruby
context = sdk.create_context(
  units: {
    session_id: session[:id],
    customer_id: current_customer&.id
  },
  publish_delay: -1,
  refresh_period: 0
)

context.ready
```

---

#### `sdk.create_context_with(params, data)`

Create context with pre-fetched data (sync).

**Parameters:**
- `params` (Hash or ContextConfig): Context parameters
- `data` (Hash): Pre-fetched context data

**Returns:** Context instance (immediately ready)

**Example:**
```ruby
data = sdk.get_client.get_context(units: { session_id: session[:id] })

context = sdk.create_context_with(
  { units: { session_id: session[:id] } },
  data
)
```

---

### Context Class

#### State Methods

##### `context.ready?`

Check if context is ready.

**Returns:** Boolean

---

##### `context.failed?`

Check if context failed to load.

**Returns:** Boolean

---

##### `context.closed?`

Check if context is finalized.

**Returns:** Boolean

---

##### `context.ready`

Wait for context to be ready (blocks).

**Returns:** self

---

##### `context.pending`

Get count of pending events.

**Returns:** Integer

---

#### Treatment Methods

##### `context.treatment(experiment_name)`

Get variant and track exposure.

**Parameters:**
- `experiment_name` (String): Experiment name

**Returns:** Integer variant number

**Raises:**
- `ABSmartly::ContextNotReadyError` if not ready
- `ABSmartly::ContextClosedError` if finalized

**Example:**
```ruby
variant = context.treatment('exp_button_color')
```

---

##### `context.peek(experiment_name)`

Get variant without tracking exposure.

**Parameters:**
- `experiment_name` (String): Experiment name

**Returns:** Integer variant number

**Example:**
```ruby
variant = context.peek('exp_button_color')
```

---

#### Variable Methods

##### `context.variable_value(key, default_value)`

Get variable value and track exposure.

**Parameters:**
- `key` (String): Variable key
- `default_value` (any): Default value

**Returns:** Variable value or default

**Example:**
```ruby
button_text = context.variable_value('button_text', 'Buy Now')
```

---

##### `context.peek_variable_value(key, default_value)`

Get variable value without tracking exposure.

**Parameters:**
- `key` (String): Variable key
- `default_value` (any): Default value

**Returns:** Variable value or default

---

#### Custom Field Methods

##### `context.custom_field_value(experiment_name, field_name)`

Get custom field value.

**Parameters:**
- `experiment_name` (String): Experiment name
- `field_name` (String): Field name

**Returns:** Parsed field value

---

#### Goal Tracking

##### `context.track(goal_name, properties = nil)`

Track goal achievement.

**Parameters:**
- `goal_name` (String): Goal name
- `properties` (Hash, optional): Goal properties (numeric only)

**Returns:** nil

**Example:**
```ruby
context.track('purchase', amount: 99.99, items: 3)
```

---

#### Publishing

##### `context.publish`

Publish pending events immediately.

**Returns:** self

---

##### `context.refresh`

Refresh experiment data.

**Returns:** self

---

##### `context.close`

Finalize context (publish and seal).

**Returns:** self

---

### Liquid Integration

#### `ABSmartly::Liquid::Drop.new(context)`

Create Liquid drop from context.

**Parameters:**
- `context` (ABSmartly::Context): Context instance

**Returns:** Drop instance for use in Liquid templates

**Example:**
```ruby
@absmartly_drop = ABSmartly::Liquid::Drop.new(@context)

# In controller
render 'template', assigns: { 'absmartly' => @absmartly_drop }
```

---

## Configuration

### SDK Configuration

```ruby
sdk_config = {
  endpoint: String,          # Required: API endpoint URL
  api_key: String,           # Required: API key
  application: String,       # Required: Application name
  environment: String,       # Required: Environment (production, development, etc.)
  retries: Integer,          # Optional: Max HTTP retries (default: 5)
  timeout: Integer,          # Optional: HTTP timeout in ms (default: 3000)
  event_logger: Proc         # Optional: Custom event logger
}
```

### Context Configuration

```ruby
context_config = {
  units: Hash,               # Required: Unit identifiers
  publish_delay: Integer,    # Optional: Auto-publish delay in ms (-1 = disabled, default: -1)
  refresh_period: Integer,   # Optional: Auto-refresh interval in ms (0 = disabled, default: 0)
  event_logger: Proc         # Optional: Override SDK event logger
}
```

### Event Logger

```ruby
event_logger = ->(context, event_name, data) {
  case event_name
  when 'exposure'
    # Handle exposure event
  when 'goal'
    # Handle goal event
  when 'error'
    # Handle error
  end
}
```

**Event Types:**
- `ready` - Context initialized
- `refresh` - Context refreshed
- `publish` - Events published
- `exposure` - Treatment accessed
- `goal` - Goal tracked
- `close` - Context finalized
- `error` - Error occurred

---

## Error Handling

### Errors

- `ABSmartly::ContextNotReadyError` - Raised when accessing context before ready
- `ABSmartly::ContextClosedError` - Raised when accessing finalized context
- `ABSmartly::HTTPError` - Raised on HTTP errors
- `ABSmartly::TimeoutError` - Raised on timeout

### Handling Errors

```ruby
begin
  variant = context.treatment('exp_test')
rescue ABSmartly::ContextNotReadyError
  # Context not ready, use fallback
  variant = 0
rescue ABSmartly::ContextClosedError
  # Context finalized, can't track
  variant = 0
end
```

### Liquid Error Handling

```liquid
{% if absmartly.ready %}
  {% assign variant = 'exp_test' | absmartly_treatment %}
{% else %}
  {% assign variant = 0 %}
{% endif %}
```

---

## Performance Tips

1. **Cache context data** - Use Redis or memory cache for context data
2. **Pre-fetch data** - Fetch data server-side before rendering Liquid
3. **Minimize Liquid logic** - Calculate variants in controller when possible
4. **Batch publishing** - Set appropriate publish delay for batching events
5. **Use peek sparingly** - Only use peek when you truly don't want exposure tracking

---

## Best Practices

1. **Initialize once per request** - Create context in before_action or controller
2. **Use consistent units** - Same session_id/customer_id throughout request
3. **Handle not ready state** - Always check `absmartly.ready` in templates
4. **Track conversions** - Use `absmartly_track` on important user actions
5. **Finalize on exit** - Call `context.close` in after_action
6. **Monitor errors** - Log all ABsmartly errors for debugging
7. **Test fallbacks** - Ensure app works when ABsmartly is unavailable

---

## Examples

See [README.md](./README.md) for complete usage examples.
