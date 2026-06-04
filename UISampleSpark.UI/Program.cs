using ApiTestSpark;
using Microsoft.OpenApi;
using UISampleSpark.UI.Middleware;
using WebSpark.Bootswatch;
using WebSpark.HttpClientUtility.RequestResult;
using Westwind.AspNetCore.Markdown;
using System.Threading.RateLimiting;

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();

// Lightweight abuse protection: limit each client IP to 100 requests/minute.
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = async (context, token) =>
    {
        context.HttpContext.Response.Headers.RetryAfter = "60";
        await context.HttpContext.Response.WriteAsync("Too many requests. Please try again later.", token).ConfigureAwait(false);
    };

    options.AddPolicy("PerIpLimit", httpContext =>
    {
        string key = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: key,
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });
});

// Configure OpenAPI document generation
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer((document, context, cancellationToken) =>
    {
        document.Info = new OpenApiInfo
        {
            Version = "v1",
            Title = "UI Sample Spark API",
            Description = """
                Employee management API for the UI Sample Spark educational project.

                Demonstrates ASP.NET Core MVC, Razor Pages, Blazor, React, Vue, and htmx
                alongside rate limiting, API key authentication, and RFC 7807 error responses.

                **Authentication:** Pass your API key in the `X-API-Key` request header.
                """,
            Contact = new OpenApiContact
            {
                Name = "Mark Hazleton",
                Url = new Uri("https://markhazleton.com")
            }
        };
        return Task.CompletedTask;
    });
});

// Database and data access services
builder.Services.AddDbContext<EmployeeContext>(opt => 
    opt.UseInMemoryDatabase("Employee"));
builder.Services.AddScoped<IEmployeeService, EmployeeDatabaseService>();
builder.Services.AddScoped<IEmployeeClient, EmployeeDatabaseClient>();

// Seed database during startup
using (var context = new EmployeeContext())
{
    SeedDatabase.DatabaseInitialization(context);
}

// HTTP and infrastructure services
builder.Services.AddHttpClient();
builder.Services.TryAddSingleton<IHttpContextAccessor, HttpContextAccessor>();

// Application-specific services
builder.Services.AddScoped<IHttpRequestResultService, HttpRequestResultService>();
builder.Services.AddScoped<ApiKeyAuthorizationFilter>();
builder.Services.AddBootswatchThemeSwitcher();
builder.Services.AddMarkdown();

// Session and MVC configuration
builder.Services.AddSession();
builder.Services.AddRazorPages();
builder.Services.AddControllersWithViews(options =>
    options.Filters.Add(new Microsoft.AspNetCore.Mvc.AutoValidateAntiforgeryTokenAttribute()));
builder.Services.AddServerSideBlazor();

// Monitoring and diagnostics
var appInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
if (!string.IsNullOrWhiteSpace(appInsightsConnectionString))
{
    builder.Services.AddApplicationInsightsTelemetry(options =>
    {
        options.ConnectionString = appInsightsConnectionString;
    });
}
builder.Services.AddHealthChecks();

// Problem details for standardized error responses
builder.Services.AddProblemDetails();

// Global exception handler (Constitution Principle III)
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

WebApplication app = builder.Build();

// Configure middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    // Use global exception handler for standardized ProblemDetails responses
    app.UseExceptionHandler();
    app.UseHsts();
}

// OpenAPI document endpoint + ApiTestSpark harness
app.MapOpenApi();
app.MapApiTestSpark(options =>
{
    options.OpenApiUrl = "/openapi/v1.json";
    options.AuthScheme = "ApiKey";
    options.EnableDemoIntegrations = false;
});

// Request pipeline
app.UseMyHttpContext();
app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseBootswatchAll();

string[] configuredApiKeys = builder.Configuration
    .GetSection("ApiSecurity:ApiKeys")
    .Get<string[]>()?
    .Where(static key => !string.IsNullOrWhiteSpace(key))
    .Take(10)
    .ToArray() ?? [];
bool requireApiKey = builder.Configuration.GetValue("ApiSecurity:RequireApiKey", true);

if (requireApiKey && configuredApiKeys.Length > 0)
{
    app.Use(async (context, next) =>
    {
        if (!context.Request.Cookies.ContainsKey("X-API-Key"))
        {
            context.Response.Cookies.Append("X-API-Key", configuredApiKeys[0], new CookieOptions
            {
                HttpOnly = true,
                Secure = true,
                SameSite = SameSiteMode.Strict,
                IsEssential = true
            });
        }

        await next();
    });
}

app.UseRouting();

app.Use(async (context, next) =>
{
    var path = context.Request.Path.Value ?? string.Empty;
    bool hasQuery = context.Request.QueryString.HasValue;
    bool isApiPath = path.StartsWith("/api", StringComparison.OrdinalIgnoreCase);
    bool isCrudUtilityPath = path.Contains("/create", StringComparison.OrdinalIgnoreCase)
        || path.Contains("/edit", StringComparison.OrdinalIgnoreCase)
        || path.Contains("/delete", StringComparison.OrdinalIgnoreCase);

    if (hasQuery || isApiPath || isCrudUtilityPath)
    {
        context.Response.Headers["X-Robots-Tag"] = "noindex, nofollow";
    }

    await next();
});

app.UseRateLimiter();
app.UseAuthorization();
app.UseSession();

// Health check endpoint
app.MapHealthChecks("/health");

// Map controllers and pages
app.MapControllers().RequireRateLimiting("PerIpLimit");
app.MapRazorPages();
app.MapBlazorHub();

// Map MVC routes using modern endpoint routing
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.MapControllerRoute(
    name: "home",
    pattern: "home/index",
    defaults: new { controller = "Home", action = "Index" });

app.MapControllerRoute(
    name: "index",
    pattern: "index.html",
    defaults: new { controller = "Home", action = "Index" });

// Markdown middleware
app.UseMarkdown();

app.Run();

/// <summary>
/// Exposes the entry point type for integration tests.
/// </summary>
public partial class Program;
