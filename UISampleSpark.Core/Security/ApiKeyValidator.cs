using System.Security.Cryptography;
using System.Text;

namespace UISampleSpark.Core.Security;

/// <summary>
/// Validates API keys using constant-time comparison to prevent timing attacks.
/// </summary>
public static class ApiKeyValidator
{
    /// <summary>
    /// Determines whether the provided API key matches any of the configured keys
    /// using a constant-time comparison to prevent timing-based enumeration attacks.
    /// </summary>
    /// <param name="providedApiKey">The API key supplied by the caller. May be null.</param>
    /// <param name="configuredApiKeys">The set of valid API keys from configuration.</param>
    /// <returns><see langword="true"/> if the key is valid; otherwise <see langword="false"/>.</returns>
    public static bool IsApiKeyValid(string? providedApiKey, IEnumerable<string> configuredApiKeys)
    {
        if (string.IsNullOrWhiteSpace(providedApiKey))
        {
            return false;
        }

        byte[] provided = Encoding.UTF8.GetBytes(providedApiKey);
        return configuredApiKeys
            .Select(Encoding.UTF8.GetBytes)
            .Any(expected => CryptographicOperations.FixedTimeEquals(provided, expected));
    }
}
