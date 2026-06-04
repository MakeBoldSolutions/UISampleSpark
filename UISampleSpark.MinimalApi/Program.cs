using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi;
using System.Security.Cryptography;
using System.Text;
using System.Threading.RateLimiting;
using UISampleSpark.Core.Interfaces;
using UISampleSpark.Core.Models;
using UISampleSpark.Data.Models;
using UISampleSpark.Data.Services;
using UISampleSpark.MinimalApi.Helpers;
using UISampleSpark.MinimalApi.Middleware;

var builder = WebApplication.CreateBuilder(args);

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

                Demonstrates .NET 10 Minimal API patterns including rate limiting,
                API key authentication, and RFC 7807 ProblemDetails error responses.

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

builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddHealthChecks();
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

builder.Services.AddDbContext<EmployeeContext>(opt => opt.UseInMemoryDatabase("Employee"));
builder.Services.AddScoped<IEmployeeService, EmployeeDatabaseService>();
builder.Services.AddScoped<IEmployeeClient, EmployeeDatabaseClient>();
using (var seedContext = new EmployeeContext())
{
    SeedDatabase.DatabaseInitialization(seedContext);
}

string[] configuredApiKeys = builder.Configuration
    .GetSection("ApiSecurity:ApiKeys")
    .Get<string[]>()?
    .Where(static key => !string.IsNullOrWhiteSpace(key))
    .Take(10)
    .ToArray() ?? [];
bool requireApiKey = builder.Configuration.GetValue("ApiSecurity:RequireApiKey", true);

ValueTask<object?> ApiKeyFilter(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
{
    if (!IsApiKeyAuthorized(context.HttpContext.Request, requireApiKey, configuredApiKeys))
    {
        return ValueTask.FromResult<object?>(Results.Unauthorized());
    }

    return next(context);
}

var app = builder.Build();

app.UseExceptionHandler();
app.MapOpenApi();
app.MapGet("/swagger", () => Results.Redirect("https://apitest.makeboldspark.com/")).ExcludeFromDescription();
app.UseHttpsRedirection();
app.UseRateLimiter();

app.MapHealthChecks("/health");

app.MapGet("/employees", async (IEmployeeService employeeService, CancellationToken token) =>
{
    var paging = new PagingParameterModel();
    var employees = await employeeService.GetEmployeesAsync(paging, token).ConfigureAwait(false);
    return employees;
})
.WithName("GetEmployees")
.WithTags("Employees: Query")
.WithSummary("List all employees")
.WithDescription("""
    Returns the full list of employees using default paging.

    Results are sorted by employee ID. Use the departments endpoint
    to look up valid department values.
    """)
.Produces<EmployeeList>(StatusCodes.Status200OK)
.Produces<ProblemDetails>(StatusCodes.Status429TooManyRequests)
.Produces(StatusCodes.Status401Unauthorized)
.AddEndpointFilter(ApiKeyFilter)
.RequireRateLimiting("PerIpLimit");

app.MapGet("/employees/{id}", async (IEmployeeService employeeService, int id, CancellationToken token) =>
{
    var employee = await employeeService.FindEmployeeByIdAsync(id, token).ConfigureAwait(false);
    if (employee == null)
    {
        return Results.NotFound();
    }
    return Results.Ok(employee);
})
.WithName("GetEmployeeById")
.WithTags("Employees: Query")
.WithSummary("Get employee by ID")
.WithDescription("Returns a single employee record matching the provided integer ID.")
.Produces<EmployeeDto>(StatusCodes.Status200OK)
.Produces<ProblemDetails>(StatusCodes.Status404NotFound)
.Produces<ProblemDetails>(StatusCodes.Status429TooManyRequests)
.Produces(StatusCodes.Status401Unauthorized)
.AddEndpointFilter(ApiKeyFilter)
.RequireRateLimiting("PerIpLimit");

app.MapPost("/employees", async (IEmployeeService employeeService, EmployeeDto employee, CancellationToken token) =>
{
    var result = await employeeService.SaveAsync(employee, token).ConfigureAwait(false);
    if (result is null || result.Resource is null || !result.Success)
    {
        return Results.BadRequest("Employee not saved");
    }

    return Results.Created($"/employees/{result.Resource.Id}", result);
})
.WithName("CreateEmployee")
.WithTags("Employees: Command")
.WithSummary("Create a new employee")
.WithDescription("""
    Creates a new employee record. The request body must include all required fields:
    `name`, `age` (minimum 18), `state`, `country`, and `department`.

    Returns **201 Created** with the saved employee wrapped in a response envelope.
    """)
.Produces<EmployeeResponse>(StatusCodes.Status201Created)
.Produces<ProblemDetails>(StatusCodes.Status400BadRequest)
.Produces<ProblemDetails>(StatusCodes.Status429TooManyRequests)
.Produces(StatusCodes.Status401Unauthorized)
.AddEndpointFilter(ApiKeyFilter)
.RequireRateLimiting("PerIpLimit");

app.MapGet("/departments", async (IEmployeeService employeeService, CancellationToken token) =>
{
    var departments = await employeeService.GetDepartmentsAsync(false, token).ConfigureAwait(false);
    return departments;
})
.WithName("GetDepartments")
.WithTags("Departments: Query")
.WithSummary("List all departments")
.WithDescription("Returns all departments defined in the system, excluding soft-deleted entries.")
.Produces<DepartmentDto[]>(StatusCodes.Status200OK)
.Produces<ProblemDetails>(StatusCodes.Status429TooManyRequests)
.Produces(StatusCodes.Status401Unauthorized)
.AddEndpointFilter(ApiKeyFilter)
.RequireRateLimiting("PerIpLimit");

app.Run();

static bool IsApiKeyAuthorized(HttpRequest request, bool requireApiKey, IReadOnlyCollection<string> configuredApiKeys)
{
    if (!requireApiKey)
    {
        return true;
    }

    if (configuredApiKeys.Count == 0)
    {
        return true;
    }

    string? providedApiKey = null;
    if (request.Headers.TryGetValue("X-API-Key", out var headerValue))
    {
        providedApiKey = headerValue.ToString();
    }
    else if (request.Cookies.TryGetValue("X-API-Key", out var cookieValue))
    {
        providedApiKey = cookieValue;
    }

    if (string.IsNullOrWhiteSpace(providedApiKey))
    {
        return false;
    }

    byte[] provided = Encoding.UTF8.GetBytes(providedApiKey);
    return configuredApiKeys
        .Select(Encoding.UTF8.GetBytes)
        .Any(expected => CryptographicOperations.FixedTimeEquals(provided, expected));
}
