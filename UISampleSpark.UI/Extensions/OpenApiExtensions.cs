using Microsoft.OpenApi;

namespace UISampleSpark.UI.Extensions;

/// <summary>
/// OpenAPI document configuration for the UI Sample Spark minimal API endpoints.
/// </summary>
public static class OpenApiExtensions
{
    /// <summary>
    /// Registers OpenAPI document generation with document metadata, the <c>X-API-Key</c>
    /// security scheme, tag descriptions, and per-operation security and parameter descriptions.
    /// </summary>
    /// <param name="services">The service collection.</param>
    /// <returns>The service collection for chaining.</returns>
    public static IServiceCollection AddUISampleSparkOpenApi(this IServiceCollection services)
    {
        services.AddOpenApi(options =>
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

        return services;
    }
}
