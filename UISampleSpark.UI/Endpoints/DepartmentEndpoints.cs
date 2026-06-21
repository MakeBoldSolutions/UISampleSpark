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
            .AddEndpointFilter<ApiKeyEndpointFilter>()
            .RequireRateLimiting("PerIpLimit");

        group.MapGet("", GetAllAsync)
            .WithName("ListDepartments")
            .WithSummary("List departments")
            .WithDescription("Returns all departments. Set `includeEmployees=true` to embed the full employee list in each department object.")
            .Produces<IEnumerable<DepartmentDto>>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapGet("{id:int}", GetByIdAsync)
            .WithName("GetDepartment")
            .WithSummary("Get department by ID")
            .WithDescription("Returns the department matching the given numeric ID. Optionally includes the employee roster via query parameter.")
            .Produces<DepartmentDto>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        return app;
    }

    private static async Task<IResult> GetAllAsync(
        IEmployeeService employeeService,
        CancellationToken cancellationToken,
        [Microsoft.AspNetCore.Mvc.FromQuery] bool includeEmployees = false)
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
