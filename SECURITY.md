# Security Best Practices

This document outlines security considerations when using the ABsmartly Liquid SDK.

## Critical Security Requirements

### 1. Never Expose API Keys Client-Side

**CRITICAL:** Never include your ABsmartly API key in client-side JavaScript or Liquid templates that render in the browser.

**Bad Example:**
```liquid
<script>
  window.absmartlyConfig = {
    apiKey: '{{ settings.absmartly_api_key }}'  // NEVER DO THIS
  };
</script>
```

**Why this is dangerous:**
- Anyone viewing your page source can read the API key
- If the key has write/admin permissions, attackers can manipulate experiments
- Attackers can push fake tracking events
- Attackers can read experiment configurations

**Correct Approach:**
- Use the SDK server-side only in Liquid templates
- Pre-fetch experiment data server-side
- If you need client-side tracking, use a separate read-only public key (if your ABsmartly plan supports it)

### 2. Always Use JSON Escaping in JavaScript Contexts

When interpolating Liquid variables into `<script>` tags, **always** use the `| json` filter to prevent XSS attacks.

**Bad Example:**
```liquid
<script>
  var shopName = '{{ shop.name }}';  // VULNERABLE TO XSS
  var sessionId = '{{ session_id }}';  // VULNERABLE TO XSS
</script>
```

**Why this is dangerous:**
- If `shop.name` contains `'; alert(document.cookie); //`, it breaks out of the string
- If `shop.name` contains `</script>`, it breaks out of the script tag entirely
- Attackers can execute arbitrary JavaScript in users' browsers

**Correct Approach:**
```liquid
<script>
  var shopName = {{ shop.name | json }};  // SAFE - properly escaped
  var sessionId = {{ session_id | json }};  // SAFE - properly escaped
</script>
```

Or even better, build the entire object server-side:
```liquid
{% capture config_data %}
{
  "shopName": {{ shop.name | json }},
  "sessionId": {{ session_id | json }}
}
{% endcapture %}

<script>
  var config = {{ config_data | strip | json }};
</script>
```

### 3. Validate User-Controlled Data

Never pass user-controlled data directly to experiment names, goal names, or properties without validation.

**Example:**
```ruby
# In your Shopify app or controller
experiment_name = params[:experiment]  # User-controlled input

# Validate against whitelist
allowed_experiments = ['exp_header_test', 'exp_button_color', 'exp_pricing']
unless allowed_experiments.include?(experiment_name)
  experiment_name = 'default_experiment'
end

# Now safe to use in template
assigns['experiment_name'] = experiment_name
```

### 4. Content Security Policy

Implement Content Security Policy (CSP) headers to mitigate XSS impact:

```
Content-Security-Policy: script-src 'self' 'unsafe-inline' https://cdn.absmartly.com;
```

Note: The Liquid SDK renders templates server-side, so inline scripts are common. Consider using nonces for better CSP:

```liquid
<script nonce="{{ csp_nonce }}">
  // Your code here
</script>
```

## Thread Safety

### Context Injection Required

The SDK **requires** explicit context injection via the Drop object. The global fallback (`ABsmartly::Liquid.current_context`) has been removed as it was thread-unsafe and caused cross-user data contamination.

**Correct Setup:**

```ruby
# In your Shopify app or Rails controller
def index
  # Create context per request
  context = absmartly_sdk.create_context(
    units: { session_id: session.id }
  )

  # Inject via Drop
  @absmartly = ABsmartly::Liquid::Drop.new(context)

  # Render template with assigns
  template = Liquid::Template.parse(liquid_template_source)
  template.render('absmartly' => @absmartly)
end
```

**Never:**
- Use a shared global context across requests
- Reuse context objects between requests
- Set `ABsmartly::Liquid.current_context` (removed — use Drop injection instead)

## Privacy Considerations

### PII in Unit Identifiers

Be careful about what data you use as unit identifiers:

**Recommended:**
```ruby
units = {
  session_id: SecureRandom.uuid,  # Anonymous session token
  anonymous_id: cookies[:anonymous_id]
}
```

**Avoid:**
```ruby
units = {
  email: user.email,  # PII
  ip_address: request.remote_ip,  # PII
  full_name: user.name  # PII
}
```

### GDPR/CCPA Compliance

If you use customer IDs or other identifiers:
1. Disclose A/B testing in your privacy policy
2. Provide opt-out mechanisms
3. Handle data deletion requests
4. Don't expose unit IDs in client-side code

## Error Handling Modes

The SDK provides two error handling modes:

### Graceful Mode (Default)

Errors are logged but don't crash page rendering:

```ruby
ABsmartly::Liquid.strict_mode = false  # Default
```

Behavior:
- Missing context → returns control variant (0) + logs warning
- SDK errors → returns safe defaults + logs error
- Pages always render successfully

Use for: **Production environments**

### Strict Mode

Errors raise exceptions immediately:

```ruby
ABsmartly::Liquid.strict_mode = true
```

Behavior:
- Missing context → raises exception
- SDK errors → propagates exception
- Pages crash if SDK misconfigured

Use for: **Development and staging environments** to catch configuration issues early

## Logging Configuration

Configure logging to monitor SDK health:

```ruby
# Use your application's logger
ABsmartly::Liquid.logger = Rails.logger

# Or custom logger
ABsmartly::Liquid.logger = Logger.new('log/absmartly.log')
ABsmartly::Liquid.logger.level = Logger::WARN

# Disable logging
ABsmartly::Liquid.logger = Logger.new('/dev/null')
```

**Monitor these warnings in production:**
- "ABsmartly context missing" - indicates Drop not injected
- "ABsmartly context not ready" - indicates SDK initialization failure
- "event dropped" - indicates lost tracking data

## Example Templates Security Review

The example templates in `examples/shopify-theme/` have been updated to follow these security practices. Review them before using in production.

Key changes:
- All JavaScript interpolations use `| json` filter
- API keys removed from client-side code
- Null checks added for DOM operations
- Proper type validation for numeric values

## Security Reporting

If you discover a security vulnerability in this SDK, please report it to:
- Email: security@absmartly.com
- Do not open public GitHub issues for security vulnerabilities

## References

- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [Shopify Liquid Security](https://shopify.dev/docs/api/liquid)
- [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)
