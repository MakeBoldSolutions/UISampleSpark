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
            .WithGroupName("Employee API")
            .AddEndpointFilter<ApiKeyEndpointFilter>()
            .RequireRateLimiting("PerIpLimit");

        group.MapGet("", ListAsync)
            .WithName("ListEmployees")
            .Produces<IEnumerable<EmployeeDto>>(StatusCodes.Status200OK);

        group.MapGet("{id:int}", FindByIdAsync)
            .WithName("GetEmployee")
            .Produces<EmployeeResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest);

        group.MapPost("", PostAsync)
            .WithName("CreateEmployee")
            .Produces<EmployeeDto>(StatusCodes.Status201Created)
            .ProducesProblem(StatusCodes.Status400BadRequest);

        group.MapPut("{id:int}", PutAsync)
            .WithName("UpdateEmployee")
            .Produces<EmployeeResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest);

        group.MapDelete("{id:int}", DeleteAsync)
            .WithName("DeleteEmployee")
            .Produces<EmployeeResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest);

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
