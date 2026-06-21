using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using UISampleSpark.Core.Exceptions;

namespace UISampleSpark.UI.Middleware;

/// <summary>
/// Global exception handler that converts unhandled exceptions to RFC 7807 ProblemDetails responses.
/// Implements Principle III of the project constitution (Error Handling &amp; API Contracts).
/// </summary>
/// <remarks>
/// This handler centralizes exception handling across the application, ensuring consistent
/// error responses that conform to the ProblemDetails standard. It provides detailed error
/// information in development mode while protecting sensitive data in production.
/// </remarks>
public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;
    private readonly IHostEnvironment _environment;

    /// <summary>
    /// Initializes a new instance of the <see cref="GlobalExceptionHandler"/> class.
    /// </summary>
    /// <param name="logger">Logger for exception tracking and diagnostics.</param>
    /// <param name="environment">Host environment to determine error detail visibility.</param>
    public GlobalExceptionHandler(
        ILogger<GlobalExceptionHandler> logger,
        IHostEnvironment environment)
    {
        _logger = logger;
        _environment = environment;
    }

    /// <summary>
    /// Handles exceptions by logging them and returning standardized ProblemDetails responses.
    /// </summary>
    /// <param name="httpContext">The HTTP context for the current request.</param>
    /// <param name="exception">The unhandled exception that occurred.</param>
    /// <param name="cancellationToken">Cancellation token for async operations.</param>
    /// <returns>
    /// A <see cref="ValueTask{Boolean}"/> that returns true to indicate the exception was handled.
    /// </returns>
    /// <remarks>
    /// Exception handling behavior:
    /// - Development: Returns detailed error messages, stack traces, and inner exceptions
    /// - Production: Returns generic error messages to prevent information disclosure
    /// - All environments: Logs full exception details with TraceId for correlation
    /// </remarks>
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(httpContext);
        ArgumentNullException.ThrowIfNull(exception);

        var traceId = Activity.Current?.Id ?? httpContext.TraceIdentifier;

        // Sanitize user-controlled values to prevent log forging via injected newlines
        var sanitizedPath = (httpContext.Request.Path.Value ?? "/")
            .Replace("\r", "", StringComparison.Ordinal)
            .Replace("\n", "", StringComparison.Ordinal);
        var sanitizedMethod = httpContext.Request.Method
            .Replace("\r", "", StringComparison.Ordinal)
            .Replace("\n", "", StringComparison.Ordinal);

        // Log the exception with full details and structured data
        _logger.LogError(
            exception,
            "Unhandled exception occurred. TraceId: {TraceId}, Path: {Path}, Method: {Method}, User: {User}",
            traceId,
            sanitizedPath,
            sanitizedMethod,
            httpContext.User?.Identity?.Name ?? "Anonymous");

        // Determine appropriate HTTP status code based on exception type
        var statusCode = ExceptionHttpMapper.DetermineStatusCode(exception);

        // Build RFC 7807 compliant ProblemDetails response
        var problemDetails = new ProblemDetails
        {
            Status = statusCode,
            Title = ExceptionHttpMapper.GetTitleForStatusCode(statusCode),
            Detail = ExceptionHttpMapper.GetDetailMessage(exception, _environment.IsDevelopment()),
            Instance = httpContext.Request.Path,
            Type = $"https://httpstatuses.com/{statusCode}",
            Extensions =
            {
                ["traceId"] = traceId,
                ["timestamp"] = DateTime.UtcNow.ToString("o"),
                ["exceptionType"] = exception.GetType().Name
            }
        };

        // Add development-only diagnostic information
        if (_environment.IsDevelopment())
        {
            problemDetails.Extensions["stackTrace"] = exception.StackTrace;
            problemDetails.Extensions["source"] = exception.Source;
            
            if (exception.InnerException != null)
            {
                problemDetails.Extensions["innerException"] = new
                {
                    message = exception.InnerException.Message,
                    type = exception.InnerException.GetType().Name
                };
            }
        }

        // Set response headers and write JSON response
        httpContext.Response.StatusCode = statusCode;
        httpContext.Response.ContentType = "application/problem+json";
        
        await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);

        return true; // Exception has been handled
    }

}
