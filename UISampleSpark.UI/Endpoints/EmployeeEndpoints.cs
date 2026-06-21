namespace UISampleSpark.UI.Endpoints;

/// <summary>
/// Minimal API endpoints for employee CRUD operations.
/// Routes mirror the former EmployeeApiController: /api/employee
/// </summary>
public static class EmployeeEndpoints
{
    /// <summary>Registers employee CRUD endpoints on the given route builder.</summary>
    public static IEndpointRouteBuilder MapEmployeeApi(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/employee")
            .WithTags("Employee")
            .AddEndpointFilter<ApiKeyEndpointFilter>()
            .RequireRateLimiting("PerIpLimit");

        group.MapGet("", ListAsync)
            .WithName("ListEmployees")
            .WithSummary("List employees")
            .WithDescription("Returns a paged list of all employees. Use `PageNumber` and `PageSize` query parameters to navigate large result sets.")
            .Produces<IEnumerable<EmployeeDto>>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapGet("{id:int}", FindByIdAsync)
            .WithName("GetEmployee")
            .WithSummary("Get employee by ID")
            .WithDescription("Returns the full employee record for the given numeric ID.")
            .Produces<EmployeeResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("", PostAsync)
            .WithName("CreateEmployee")
            .WithSummary("Create employee")
            .WithDescription("Creates a new employee record and returns it with the server-assigned ID.")
            .Produces<EmployeeDto>(StatusCodes.Status201Created)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapPut("{id:int}", PutAsync)
            .WithName("UpdateEmployee")
            .WithSummary("Update employee")
            .WithDescription("Replaces the employee record for the given ID with the supplied payload.")
            .Produces<EmployeeResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapDelete("{id:int}", DeleteAsync)
            .WithName("DeleteEmployee")
            .WithSummary("Delete employee")
            .WithDescription("Permanently removes the employee record with the given ID.")
            .Produces<EmployeeResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        return app;
    }

    private static async Task<IResult> ListAsync(
        [AsParameters] PagingParameterModel paging,
        IEmployeeService employeeService,
        CancellationToken cancellationToken)
    {
        var employees = await employeeService.GetEmployeesAsync(paging, cancellationToken).ConfigureAwait(false);
        return Results.Ok(employees);
    }

    private static async Task<IResult> FindByIdAsync(
        int id,
        IEmployeeService employeeService,
        CancellationToken cancellationToken)
    {
        EmployeeResponse result = await employeeService.FindEmployeeByIdAsync(id, cancellationToken).ConfigureAwait(false);
        return result.Success ? Results.Ok(result) : Results.BadRequest(result);
    }

    private static async Task<IResult> PostAsync(
        EmployeeDto? employee,
        IEmployeeService employeeService,
        CancellationToken cancellationToken)
    {
        if (employee is null)
            return Results.BadRequest(new { error = "Employee was null" });

        EmployeeResponse result = await employeeService.SaveAsync(employee, cancellationToken).ConfigureAwait(false);
        if (!result.Success)
            return Results.BadRequest(new { error = result.Message });

        return Results.Created($"/api/employee/{employee.Id}", employee);
    }

    private static async Task<IResult> PutAsync(
        int id,
        EmployeeDto employee,
        IEmployeeService employeeService,
        CancellationToken cancellationToken)
    {
        EmployeeResponse result = await employeeService.UpdateAsync(id, employee, cancellationToken).ConfigureAwait(false);
        return result.Success ? Results.Ok(result) : Results.BadRequest(new { error = result.Message });
    }

    private static async Task<IResult> DeleteAsync(
        int id,
        IEmployeeService employeeService,
        CancellationToken cancellationToken)
    {
        EmployeeResponse result = await employeeService.DeleteAsync(id, cancellationToken).ConfigureAwait(false);
        return result.Success ? Results.Ok(result) : Results.BadRequest(new { error = result.Message });
    }
}
