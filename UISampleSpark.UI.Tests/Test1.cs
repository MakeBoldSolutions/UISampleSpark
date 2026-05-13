using Microsoft.AspNetCore.Mvc.Testing;

namespace UISampleSpark.UI.Tests;

[TestClass]
[DoNotParallelize]
public sealed class RobotsIndexingHeadersTests
{
    private static WebApplicationFactory<Program>? _factory;
    private static HttpClient? _client;

    [ClassInitialize]
    public static void Initialize(TestContext _)
    {
        _factory = new WebApplicationFactory<Program>();
        _client = _factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false
        });
    }

    [ClassCleanup]
    public static void Cleanup()
    {
        _client?.Dispose();
        _factory?.Dispose();
    }

    [TestMethod]
    public async Task QueryStringRequest_ShouldReturnNoIndexHeader()
    {
        HttpResponseMessage response = await GetClient().GetAsync("/Employee?page=2").ConfigureAwait(false);
        string content = await response.Content.ReadAsStringAsync().ConfigureAwait(false);

        AssertHasNoIndexHeader(response);
        StringAssert.Contains(content, "<meta name=\"robots\" content=\"noindex, nofollow\" />");
        StringAssert.Contains(content, "<link rel=\"canonical\" href=\"http://localhost/Employee\" />");
        Assert.IsFalse(content.Contains("href=\"http://localhost/Employee?page=2\"", StringComparison.OrdinalIgnoreCase));
    }

    [TestMethod]
    public async Task ApiRequest_ShouldReturnNoIndexHeader()
    {
        HttpResponseMessage response = await GetClient().GetAsync("/api/employee").ConfigureAwait(false);

        AssertHasNoIndexHeader(response);
    }

    [TestMethod]
    [DataRow("/MvcEmployee/Create")]
    [DataRow("/MvcEmployee/Edit/1")]
    [DataRow("/MvcEmployee/Delete/1")]
    public async Task CrudUtilityPage_ShouldReturnNoIndexHeader(string path)
    {
        HttpResponseMessage response = await GetClient().GetAsync(path).ConfigureAwait(false);

        AssertHasNoIndexHeader(response);
    }

    private static HttpClient GetClient()
    {
        return _client ?? throw new InvalidOperationException("Test client not initialized.");
    }

    private static void AssertHasNoIndexHeader(HttpResponseMessage response)
    {
        bool hasHeader = response.Headers.TryGetValues("X-Robots-Tag", out IEnumerable<string>? values);
        Assert.IsTrue(hasHeader, "Expected X-Robots-Tag header to be present.");

        string actualValue = string.Join(",", values ?? []);
        Assert.IsTrue(
            actualValue.Contains("noindex", StringComparison.OrdinalIgnoreCase)
            && actualValue.Contains("nofollow", StringComparison.OrdinalIgnoreCase),
            $"Expected X-Robots-Tag to include 'noindex, nofollow', but got '{actualValue}'.");
    }
}
