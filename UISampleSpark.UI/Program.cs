using ApiTestSpark;
using Microsoft.OpenApi;
using UISampleSpark.UI.Middleware;
using WebSpark.Bootswatch;
using WebSpark.HttpClientUtility.RequestResult;
using Westwind.AspNetCore.Markdown;
using System.Threading.RateLimiting;

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);


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
    // Document-level metadata: info, security schemes, and tag descriptions
    options.AddDocumentTransformer((document, context, cancellationToken) =>
    {
        document.Info = new OpenApiInfo
        {
            Version = "v1",
            Title = "UI Sample Spark API",
            Description = """
                Employee management REST API for the UI Sample Spark educational project.

                Demonstrates ASP.NET Core minimal APIs alongside MVC, Razor Pages, Blazor,
                React, Vue, and htmx — with per-IP rate limiting, API key authentication,
                and RFC 7807 ProblemDetails error responses.

                **Authentication:** All `/api/*` endpoints require an `X-API-Key` header.
                Contact the site owner to obtain a valid key.
                """,
            Contact = new OpenApiContact
            {
                Name = "Mark Hazleton",
                Url = new Uri("https://markhazleton.com")
            },
            License = new OpenApiLicense
            {
                Name = "MIT",
                Url = new Uri("https://github.com/markhazleton/UISampleSpark/blob/main/LICENSE")
            }
        };

        // X-API-Key security scheme (header-based)
        document.Components ??= new OpenApiComponents();
        document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();
        document.Components.SecuritySchemes["ApiKey"] = new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.ApiKey,
            In = ParameterLocation.Header,
            Name = "X-API-Key",
            Description = "API key for `/api/*` endpoints. Pass in the `X-API-Key` request header. " +
                          "Valid keys are configured in `ApiSecurity:ApiKeys` in app settings."
        };

        // Tag-level descriptions surfaced in tools like ApiTestSpark and Swagger UI
        document.Tags = new HashSet<OpenApiTag>
        {
            new OpenApiTag
            {
                Name = "Employee",
                Description = "Create, read, update, and delete employee records. " +
                              "All operations require a valid `X-API-Key` header."
            },
            new OpenApiTag
            {
                Name = "Department",
                Description = "Query departments and optionally include their employee rosters. " +
                              "All operations require a valid `X-API-Key` header."
            },
            new OpenApiTag
            {
                Name = "Status",
                Description = "Application health check, build version metadata, and live endpoint discovery. " +
                              "No authentication required."
            }
        };

        // Global security: all operations default to requiring the ApiKey scheme.
        // Public operations override this with security:[] via the operation transformer below.
        document.Security =
        [
            new OpenApiSecurityRequirement
            {
                {
                    new OpenApiSecuritySchemeReference("ApiKey", document, null),
                    []
                }
            }
        ];

        return Task.CompletedTask;
    });

    // Operation transformer: override security and enrich parameter descriptions
    options.AddOperationTransformer((operation, context, cancellationToken) =>
    {
        var path = context.Description.RelativePath ?? string.Empty;

        // Public endpoints — clear global security requirement so they are accessible without a key
        if (!path.StartsWith("api/", StringComparison.OrdinalIgnoreCase))
        {
            operation.Security = [];
        }

        // Enrich parameter descriptions
        foreach (var parameter in operation.Parameters ?? [])
        {
            if (parameter.Name.Equals("id", StringComparison.OrdinalIgnoreCase)
                && parameter.In == ParameterLocation.Path)
            {
                parameter.Description = path.Contains("department", StringComparison.OrdinalIgnoreCase)
                    ? "Unique numeric identifier of the department."
                    : "Unique numeric identifier of the employee.";
            }
            else if (parameter.Name.Equals("PageNumber", StringComparison.OrdinalIgnoreCase))
            {
                parameter.Description = "1-based page number. Defaults to 1.";
            }
            else if (parameter.Name.Equals("PageSize", StringComparison.OrdinalIgnoreCase))
            {
                parameter.Description = "Records per page, 1–5,000. Defaults to 300.";
            }
            else if (parameter.Name.Equals("includeEmployees", StringComparison.OrdinalIgnoreCase))
            {
                parameter.Description = "When true, each department object includes its full employee roster.";
            }
        }

        return Task.CompletedTask;
    });
});

// Database and data access services
builder.Services.AddDbContext<UISampleSpark.Core.Models.Data.EmployeeContext>(opt => 
    opt.UseInMemoryDatabase("Employee"));
builder.Services.AddScoped<IEmployeeService, UISampleSpark.Core.Services.EmployeeDatabaseService>();
builder.Services.AddScoped<IEmployeeClient, UISampleSpark.Core.Services.EmployeeDatabaseClient>();

// Seed database during startup
using (var context = new UISampleSpark.Core.Models.Data.EmployeeContext())
{
    SeedDatabase.DatabaseInitialization(context);
}

// HTTP and infrastructure services
builder.Services.AddHttpClient();
builder.Services.TryAddSingleton<IHttpContextAccessor, HttpContextAccessor>();

// Application-specific services
builder.Services.AddScoped<IHttpRequestResultService, HttpRequestResultService>();
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

// Map minimal API endpoints
app.MapEmployeeApi();
app.MapDepartmentApi();
app.MapStatusApi();

// Map view controllers and pages
app.MapControllers();
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
