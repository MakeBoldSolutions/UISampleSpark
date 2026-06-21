using UISampleSpark.Core.Security;

namespace UISampleSpark.UI.Endpoints;

/// <summary>
/// Endpoint filter that validates an API key from the request header or cookie.
/// </summary>
public sealed class ApiKeyEndpointFilter : IEndpointFilter
{
    private const string ApiKeyHeader = "X-API-Key";
    private const int MaxConfiguredKeys = 10;

    /// <inheritdoc />
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);
        var config = context.HttpContext.RequestServices.GetRequiredService<IConfiguration>();

        bool requireApiKey = config.GetValue("ApiSecurity:RequireApiKey", true);
        if (!requireApiKey)
            return await next(context).ConfigureAwait(false);

        string[] configuredApiKeys = config
            .GetSection("ApiSecurity:ApiKeys")
            .Get<string[]>()?
            .Where(static k => !string.IsNullOrWhiteSpace(k))
            .Take(MaxConfiguredKeys)
            .ToArray() ?? [];

        if (configuredApiKeys.Length == 0)
            return await next(context).ConfigureAwait(false);

        var request = context.HttpContext.Request;
        string? providedKey = null;

        if (request.Headers.TryGetValue(ApiKeyHeader, out var headerValue))
            providedKey = headerValue.ToString();
        else if (request.Cookies.TryGetValue(ApiKeyHeader, out var cookieValue))
            providedKey = cookieValue;

        if (!ApiKeyValidator.IsApiKeyValid(providedKey, configuredApiKeys))
            return Results.Unauthorized();

        return await next(context).ConfigureAwait(false);
    }
}
