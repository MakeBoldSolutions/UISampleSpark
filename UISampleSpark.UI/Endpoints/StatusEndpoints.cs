namespace UISampleSpark.UI.Endpoints;

/// <summary>
/// Minimal API endpoints for application status.
/// Routes mirror the former StatusController: /status
/// </summary>
public static class StatusEndpoints
{
    /// <summary>Registers status endpoints on the given route builder.</summary>
    public static IEndpointRouteBuilder MapStatusApi(this IEndpointRouteBuilder app)
    {
        app.MapGet("/status", () => new ApplicationStatus(Assembly.GetExecutingAssembly()))
            .WithTags("Status")
            .WithName("GetStatus")
            .Produces<ApplicationStatus>(StatusCodes.Status200OK)
            .RequireRateLimiting("PerIpLimit");

        app.MapGet("/status/explorer", (IEnumerable<EndpointDataSource> endpointSources) =>
        {
            var routes = endpointSources
                .SelectMany(s => s.Endpoints)
                .OfType<RouteEndpoint>()
                .Select(e => new
                {
                    relativePath = e.RoutePattern.RawText,
                    methods = e.Metadata.GetMetadata<HttpMethodMetadata>()?.HttpMethods ?? []
                })
                .OrderBy(e => e.relativePath)
                .ToList();

            return Results.Ok(routes);
        })
        .WithTags("Status")
        .WithName("GetApiExplorer")
        .Produces(StatusCodes.Status200OK)
        .RequireRateLimiting("PerIpLimit");

        return app;
    }
}
