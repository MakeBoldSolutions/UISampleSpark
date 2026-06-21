namespace UISampleSpark.UI.Endpoints;

/// <summary>
/// Minimal API endpoints for department queries.
/// Routes mirror the former DepartmentApiController: /api/department
/// </summary>
public static class DepartmentEndpoints
{
    /// <summary>Registers department query endpoints on the given route builder.</summary>
    public static IEndpointRouteBuilder MapDepartmentApi(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/department")
            .WithTags("Department")
            .WithGroupName("Department API")
            .AddEndpointFilter<ApiKeyEndpointFilter>()
            .RequireRateLimiting("PerIpLimit");

        group.MapGet("", GetAllAsync)
            .WithName("ListDepartments")
            .Produces<IEnumerable<DepartmentDto>>(StatusCodes.Status200OK);

        group.MapGet("{id:int}", GetByIdAsync)
            .WithName("GetDepartment")
            .Produces<DepartmentDto>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status404NotFound);

        return app;
    }

    private static async Task<IResult> GetAllAsync(
        bool includeEmployees,
        IEmployeeService employeeService,
        CancellationToken cancellationToken)
    {
        var departments = await employeeService.GetDepartmentsAsync(includeEmployees, cancellationToken).ConfigureAwait(false);
        return Results.Ok(departments);
    }

    private static async Task<IResult> GetByIdAsync(
        int id,
        IEmployeeService employeeService,
        CancellationToken cancellationToken)
    {
        DepartmentDto department = await employeeService.FindDepartmentByIdAsync(id, cancellationToken).ConfigureAwait(false);
        return department is null
            ? Results.NotFound(new { error = "Department not found" })
            : Results.Ok(department);
    }
}
