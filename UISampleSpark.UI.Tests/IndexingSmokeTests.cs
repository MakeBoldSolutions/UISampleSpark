using Microsoft.AspNetCore.Mvc.Testing;

namespace UISampleSpark.UI.Tests;

[TestClass]
[DoNotParallelize]
public sealed class IndexingSmokeTests
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
    public async Task StartupAndIndexingFlow_ShouldBehaveAsExpected()
    {
        HttpResponseMessage home = await GetClient().GetAsync("/").ConfigureAwait(false);
        string homeHtml = await home.Content.ReadAsStringAsync().ConfigureAwait(false);

        Assert.AreEqual(HttpStatusCode.OK, home.StatusCode);
        Assert.IsFalse(home.Headers.Contains("X-Robots-Tag"));
        StringAssert.Contains(homeHtml, "<meta name=\"robots\" content=\"index, follow\" />");

        HttpResponseMessage queryPage = await GetClient().GetAsync("/Employee?page=1").ConfigureAwait(false);
        string queryHtml = await queryPage.Content.ReadAsStringAsync().ConfigureAwait(false);

        Assert.AreEqual(HttpStatusCode.OK, queryPage.StatusCode);
        Assert.IsTrue(queryPage.Headers.TryGetValues("X-Robots-Tag", out IEnumerable<string>? values));
        string robotsHeader = string.Join(",", values ?? []);
        StringAssert.Contains(robotsHeader, "noindex");
        StringAssert.Contains(robotsHeader, "nofollow");
        StringAssert.Contains(queryHtml, "<link rel=\"canonical\" href=\"http://localhost/Employee\" />");
    }

    private static HttpClient GetClient()
    {
        return _client ?? throw new InvalidOperationException("Test client not initialized.");
    }
}
