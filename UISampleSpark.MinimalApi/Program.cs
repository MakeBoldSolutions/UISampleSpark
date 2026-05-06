using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi;
using UISampleSpark.Core.Interfaces;
using UISampleSpark.Core.Models;
using UISampleSpark.Data.Models;
using UISampleSpark.Data.Services;
using UISampleSpark.MinimalApi.Helpers;
using UISampleSpark.MinimalApi.Middleware;
using UISampleSpark.MinimalApi.Endpoints;
using System.Threading.RateLimiting;
using System.Security.Cryptography;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
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
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Version = "v8",
        Title = "UI Sample Spark API",
        Description = "Employee management API for UI Sample Spark",
        Contact = new OpenApiContact
        {
            Name = "Mark Hazleton",
            Url = new Uri("https://markhazleton.com")
        },
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

// Configure the HTTP request pipeline.
app.UseExceptionHandler();
app.UseSwagger();
app.UseSwaggerUI();
app.UseHttpsRedirection();
app.UseRateLimiter();

app.MapHealthChecks("/health");

app.MapPost("/employees", async (IEmployeeService employeeService, EmployeeDto employee, CancellationToken token) =>
{
    var result = await employeeService.SaveAsync(employee, token);
    if (result is null)
    {
        return Results.BadRequest("Employee not saved");
    }
    if (result.Resource is null)
    {
        return Results.BadRequest("Employee not saved");
    }
    if (!result.Success)
    {
        return Results.BadRequest("Employee not saved");
    }

    return Results.Created($"/employees/{result.Resource.Id}", result);
}).AddEndpointFilter(ApiKeyFilter).RequireRateLimiting("PerIpLimit");

app.MapGet("/employees", async (IEmployeeService employeeService, CancellationToken token) =>
{
    var paging = new PagingParameterModel();
    var employees = await employeeService.GetEmployeesAsync(paging, token);
    return employees;
}).AddEndpointFilter(ApiKeyFilter).RequireRateLimiting("PerIpLimit");

app.MapGet("/employees/{id}", async (IEmployeeService employeeService, int id, CancellationToken token) =>
{
    var employee = await employeeService.FindEmployeeByIdAsync(id, token);
    if (employee == null)
    {
        return Results.NotFound();
    }
    return Results.Ok(employee);
}).AddEndpointFilter(ApiKeyFilter).RequireRateLimiting("PerIpLimit");

app.MapGet("/departments", async (IEmployeeService employeeService, CancellationToken token) =>
{
    var employee = await employeeService.GetDepartmentsAsync(false, token);
    return employee;
}).AddEndpointFilter(ApiKeyFilter).RequireRateLimiting("PerIpLimit");

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

