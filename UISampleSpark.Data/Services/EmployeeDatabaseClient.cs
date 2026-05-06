namespace UISampleSpark.Data.Services;

/// <summary>
/// Client wrapper for employee service operations with logging.
/// </summary>
/// <remarks>
/// This class provides a thin client layer over <see cref="IEmployeeService"/>
/// that adds structured logging for all operations. Follows the repository pattern
/// to abstract data access from consumers.
/// </remarks>
public partial class EmployeeDatabaseClient : IEmployeeClient
{
    private readonly IEmployeeService service;
    private readonly ILogger<EmployeeDatabaseClient> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="EmployeeDatabaseClient"/> class.
    /// </summary>
    /// <param name="service">The underlying employee service for data operations.</param>
    /// <param name="logger">Logger for structured logging and diagnostics.</param>
    public EmployeeDatabaseClient(IEmployeeService service, ILogger<EmployeeDatabaseClient> logger)
    {
        this.service = service;
        _logger = logger;
    }

    public async Task<int> AddMultipleEmployeesAsync(string[] namelist)
    {
        return await service.AddMultipleEmployeesAsync(namelist).ConfigureAwait(false);
    }

    public async Task<EmployeeResponse> DeleteAsync(int id, CancellationToken token)
    {
        LogDeletingEmployee(_logger, id);
        return await service.DeleteAsync(id, token).ConfigureAwait(false);
    }

    public async Task<DepartmentDto> FindDepartmentByIdAsync(int id, CancellationToken token)
    {
        return await service.FindDepartmentByIdAsync(id, token).ConfigureAwait(false);
    }

    public async Task<EmployeeResponse> FindEmployeeByIdAsync(int id, CancellationToken token)
    {
        LogFindingEmployee(_logger, id);
        return await service.FindEmployeeByIdAsync(id, token).ConfigureAwait(false);
    }

    public async Task<IEnumerable<DepartmentDto>> GetDepartmentsAsync(bool includeEmployees, CancellationToken token)
    {
        return await service.GetDepartmentsAsync(includeEmployees, token).ConfigureAwait(false);
    }

    public async Task<IEnumerable<EmployeeDto>> GetEmployeesAsync(PagingParameterModel paging, CancellationToken token)
    {
        return await service.GetEmployeesAsync(paging, token).ConfigureAwait(false);
    }

    public async Task<EmployeeResponse> SaveAsync(EmployeeDto employee, CancellationToken token)
    {
        return await service.SaveAsync(employee, token).ConfigureAwait(false);
    }

    public async Task<DepartmentResponse> SaveAsync(DepartmentDto dept, CancellationToken token)
    {
        return await service.SaveAsync(dept, token).ConfigureAwait(false);
    }

    public async Task<EmployeeResponse> UpdateAsync(int id, EmployeeDto employee, CancellationToken token)
    {
        return await service.UpdateAsync(id, employee, token).ConfigureAwait(false);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Client: Deleting employee with ID {EmployeeId}")]
    private static partial void LogDeletingEmployee(ILogger logger, int employeeId);

    [LoggerMessage(Level = LogLevel.Information, Message = "Client: Finding employee with ID {EmployeeId}")]
    private static partial void LogFindingEmployee(ILogger logger, int employeeId);
}
