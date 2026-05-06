using UISampleSpark.Core.Interfaces;

namespace UISampleSpark.MinimalApi.Endpoints;

/// <summary>
/// Extension methods for mapping the employee API endpoint group.
/// </summary>
public static class EmployeeGroupEndpoints
{
    /// <summary>
    /// Maps employee CRUD routes onto the given <see cref="RouteGroupBuilder"/>.
    /// </summary>
    /// <param name="group">The route group to extend.</param>
    /// <param name="employeeService">The employee service used by the route handlers.</param>
    /// <returns>The same <see cref="RouteGroupBuilder"/> for chaining.</returns>
    public static RouteGroupBuilder MapEmployeeApi(this RouteGroupBuilder group, IEmployeeService employeeService)
    {
        ArgumentNullException.ThrowIfNull(employeeService);

        group.MapGet("/", employeeService.GetEmployeesAsync);
        group.MapGet("/{id}", employeeService.FindDepartmentByIdAsync);
        group.MapDelete("/{id}", employeeService.DeleteAsync);
        return group;
    }
}
