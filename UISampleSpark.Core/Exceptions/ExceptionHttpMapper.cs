namespace UISampleSpark.Core.Exceptions;

/// <summary>
/// Maps exceptions to HTTP status codes, titles, and detail messages.
/// Shared by all host projects for consistent RFC 7807 ProblemDetails responses.
/// </summary>
public static class ExceptionHttpMapper
{
    /// <summary>
    /// Determines the appropriate HTTP status code for the given exception.
    /// </summary>
    public static int DetermineStatusCode(Exception exception) => exception switch
    {
        ArgumentNullException => 400,
        ArgumentException => 400,
        InvalidOperationException => 400,
        UnauthorizedAccessException => 401,
        KeyNotFoundException => 404,
        NotImplementedException => 501,
        TimeoutException => 408,
        _ => 500
    };

    /// <summary>
    /// Returns a short title string for the given HTTP status code.
    /// </summary>
    public static string GetTitleForStatusCode(int statusCode) => statusCode switch
    {
        400 => "Bad Request",
        401 => "Unauthorized",
        403 => "Forbidden",
        404 => "Not Found",
        408 => "Request Timeout",
        500 => "Internal Server Error",
        501 => "Not Implemented",
        503 => "Service Unavailable",
        _ => "Error"
    };

    /// <summary>
    /// Returns a detail message for the exception.
    /// In development mode returns the raw exception message; in production returns a safe generic message.
    /// </summary>
    public static string GetDetailMessage(Exception exception, bool isDevelopment)
    {
        if (isDevelopment)
        {
            return exception.Message;
        }

        return exception switch
        {
            ArgumentNullException => "A required parameter was not provided.",
            ArgumentException => "The request contained invalid arguments. Please check your input and try again.",
            UnauthorizedAccessException => "You do not have permission to access this resource.",
            KeyNotFoundException => "The requested resource was not found.",
            NotImplementedException => "This feature is not yet implemented.",
            TimeoutException => "The request took too long to complete. Please try again later.",
            _ => "An unexpected error occurred. Please contact support if the issue persists."
        };
    }
}
