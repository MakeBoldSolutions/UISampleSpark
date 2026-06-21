namespace UISampleSpark.Core.Services;

/// <summary>
/// Database-backed implementation of employee service using Entity Framework Core.
/// </summary>
/// <remarks>
/// This service provides CRUD operations for employees and departments using an in-memory database.
/// All operations use async/await patterns with ConfigureAwait(false) for library code compliance.
/// <para>
/// <b>Educational Note:</b> Uses InMemory database provider for demonstration purposes.
/// In production, replace with SQL Server, PostgreSQL, or other persistent provider.
/// </para>
/// </remarks>
public partial class EmployeeDatabaseService : IEmployeeService
{
    private readonly Models.Data.EmployeeContext _context;
    private readonly ILogger<Services.EmployeeDatabaseService> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="EmployeeDatabaseService"/> class.
    /// </summary>
    /// <param name="context">The database context for employee data access.</param>
    /// <param name="logger">Logger for structured logging and diagnostics.</param>
    public EmployeeDatabaseService(Models.Data.EmployeeContext context, ILogger<Services.EmployeeDatabaseService> logger)
    {
        _context = context;
        _logger = logger;
    }

    private static DepartmentDto? Create(Models.Data.Department? item)
    {
        if (item is null) return null;

        return new DepartmentDto
        {
            Id = item.Id,
            Name = item.Name,
            Description = item.Description,
            Employees = item.Employees?.Select(Create).OfType<EmployeeDto>().ToArray()
        };
    }

    private static Models.Data.Department Create(DepartmentDto item) => new()
    {
        Id = item.Id,
        Name = item.Name,
        Description = item.Description ?? string.Empty,
    };

    private static EmployeeDto? Create(Models.Data.Employee? item)
    {
        if (item is null) return null;

        return new EmployeeDto
        {
            Id = item.Id,
            Name = item.Name,
            Age = item.Age,
            State = item.State,
            Country = item.Country,
            Department = (EmployeeDepartmentEnum)(item.Department?.Id ?? 0),
            ProfilePicture = item.ProfilePicture,
            Gender = (GenderEnum)item.Gender,
            DepartmentName = item.Department?.Name ?? string.Empty,
            GenderName = ((GenderEnum)item.Gender).ToString()
        };
    }

    private static Models.Data.Employee Create(EmployeeDto item, Models.Data.Department dbDept) => new()
    {
        DepartmentId = dbDept.Id,
        Name = item.Name,
        State = item.State,
        Country = item.Country,
        Age = item.Age,
        ProfilePicture = item.ProfilePicture ?? "default.jpg",
        Gender = (Models.Data.Gender)item.Gender,
        Id = item.Id
    };

    private static EmployeeDto[] GetEmployeeDtos(List<Models.Data.Employee>? list) =>
        list?.Select(Create).OfType<EmployeeDto>().ToArray() ?? [];

    private static DepartmentDto[] GetDepartmentDtos(List<Models.Data.Department>? list) =>
        list?.Select(Create).OfType<DepartmentDto>().ToArray() ?? [];

    public async Task<int> AddMultipleEmployeesAsync(string?[]? namelist)
    {
        if (namelist is null) return -1;

        Random rand = new();
        
        var employees = namelist
            .Select(name => new Models.Data.Employee
            {
                Name = name ?? "UNKNOWN",
                Age = rand.Next(18, 100),
                Country = "USA",
                DepartmentId = rand.Next(1, Enum.GetNames<EmployeeDepartmentEnum>().Length - 1),
                Gender = (Models.Data.Gender)rand.Next(1, Enum.GetNames<Models.Data.Gender>().Length - 1),
                State = "TX"
            })
            .ToList();

        await _context.Employees.AddRangeAsync(employees).ConfigureAwait(false);
        await _context.SaveChangesAsync().ConfigureAwait(false);

        return await _context.Employees.CountAsync().ConfigureAwait(false);
    }

    public async Task<EmployeeResponse> DeleteAsync(int id, CancellationToken ct)
    {
        if (id <= 0)
            return new EmployeeResponse("Invalid Employee Id for delete");

        Models.Data.Employee? dbEmp = await _context.Employees.FindAsync([id], ct);

        if (dbEmp is null)
            return new EmployeeResponse("Employee Not Found");

        _context.Employees.Remove(dbEmp);
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return new EmployeeResponse(true);
    }

    public async Task<DepartmentDto> FindDepartmentByIdAsync(int Id, CancellationToken token)
    {
        LogFindingDepartment(_logger, Id);
        
        var department = await _context.Departments
            .Where(w => w.Id == Id)
            .Include(i => i.Employees)
            .AsNoTracking()
            .FirstOrDefaultAsync(token)
            .ConfigureAwait(false);
        
        if (department == null)
        {
            LogDepartmentNotFound(_logger, Id);
        }
            
        return Create(department);
    }

    public async Task<EmployeeResponse> FindEmployeeByIdAsync(int Id, CancellationToken token)
    {
        LogFindingEmployee(_logger, Id);
        
        EmployeeDto? employee = Create(
            await _context.Employees
                .Include(i => i.Department)
                .Where(w => w.Id == Id)
                .AsNoTracking()
                .FirstOrDefaultAsync(token)
                .ConfigureAwait(false));

        if (employee is null)
        {
            LogEmployeeNotFound(_logger, Id);
            return new EmployeeResponse("Employee Not Found");
        }
        
        LogEmployeeFound(_logger, Id, employee.Name);
        return new EmployeeResponse(employee);
    }

    public async Task<IEnumerable<DepartmentDto>> GetDepartmentsAsync(bool IncludeEmployees, CancellationToken token)
    {
        var query = _context.Departments
            .Where(w => !string.IsNullOrEmpty(w.Name));

        if (IncludeEmployees)
            query = query.Include(e => e.Employees);

        var departments = await query
            .AsNoTracking()
            .ToListAsync(token)
            .ConfigureAwait(false);

        return GetDepartmentDtos(departments);
    }

    public async Task<IEnumerable<EmployeeDto>> GetEmployeesAsync(PagingParameterModel paging, CancellationToken token)
    {
        ArgumentNullException.ThrowIfNull(paging);
        IQueryable<Models.Data.Employee> source = _context.Employees
            .Include(i => i.Department)
            .OrderBy(o => o.Name)
            .AsNoTracking();
        
        List<Models.Data.Employee> items = await source
            .Skip((paging.PageNumber - 1) * paging.PageSize)
            .Take(paging.PageSize)
            .ToListAsync(token)
            .ConfigureAwait(false);

        return GetEmployeeDtos(items);
    }

    public async Task<EmployeeResponse> SaveAsync(EmployeeDto? employee, CancellationToken token)
    {
        if (employee is null) 
            return new EmployeeResponse("Employee can not be null");
            
        return await SaveEmployeeDbAsync(employee, token).ConfigureAwait(false);
    }

    public async Task<DepartmentResponse> SaveAsync(DepartmentDto dept, CancellationToken token)
    {
        if (dept is null) 
            return new DepartmentResponse("Department can not be null");

        return await SaveDepartmentAsync(dept, token).ConfigureAwait(false);
    }

    public async Task<DepartmentResponse> SaveDepartmentAsync(DepartmentDto? item, CancellationToken cancellationToken = default)
    {
        if (item is null)
            return new DepartmentResponse("Department can not be null");

        if (item.Id <= 0)
            return new DepartmentResponse("Zero ID not allowed");

        Models.Data.Department? dbDept = await _context.Departments
            .FindAsync([item.Id], cancellationToken)
            .ConfigureAwait(false);

        if (dbDept is null)
        {
            dbDept = Create(item);
            _context.Departments.Add(dbDept);
        }
        else
        {
            dbDept.Id = item.Id;
            dbDept.Name = item.Name;
            dbDept.Description = item.Description;
        }

        await _context.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        
        return new DepartmentResponse(Create(dbDept));
    }

    public async Task<EmployeeResponse> SaveEmployeeDbAsync(EmployeeDto? newItem, CancellationToken ct = default)
    {
        if (newItem is null)
            return new EmployeeResponse("Employee can not be null");

        try
        {
            EmployeeDto item = new(
                newItem.Id,
                newItem.Name,
                newItem.Age,
                newItem.State,
                newItem.Country,
                newItem.Department,
                newItem.ProfilePicture,
                newItem.Gender);

            int deptId = (int)item.Department;
            Models.Data.Department? dbDept = await _context.Departments
                .FindAsync([deptId], ct)
                .ConfigureAwait(false);

            if (dbDept is null)
                return new EmployeeResponse("Department not found");

            Models.Data.Employee? dbEmp;

            if (item.Id > 0)
            {
                dbEmp = await _context.Employees
                    .Include(d => d.Department)
                    .Where(w => w.Id == item.Id)
                    .FirstOrDefaultAsync(ct)
                    .ConfigureAwait(false);

                if (dbEmp is null)
                {
                    dbEmp = Create(item, dbDept);
                    _context.Employees.Add(dbEmp);
                }
                else
                {
                    dbEmp.Age = item.Age;
                    dbEmp.Country = item.Country;
                    dbEmp.DepartmentId = dbDept.Id;
                    dbEmp.Department = dbDept;
                    dbEmp.Name = item.Name ?? string.Empty;
                    dbEmp.State = item.State;
                    dbEmp.LastUpdatedDate = DateTime.UtcNow;
                    dbEmp.ProfilePicture = item.ProfilePicture ?? "default.jpg";
                    dbEmp.Gender = (Models.Data.Gender)item.Gender;
                    _context.Update(dbEmp);
                }
                
                await _context.SaveChangesAsync(ct).ConfigureAwait(false);
            }
            else
            {
                dbEmp = Create(item, dbDept);
                _context.Employees.Add(dbEmp);
                await _context.SaveChangesAsync(ct).ConfigureAwait(false);
            }

            Models.Data.Employee? local = _context.Set<Models.Data.Employee>()
                .Local
                .FirstOrDefault(entry => entry.Id.Equals(item.Id));

            if (local is not null)
            {
                _context.Entry(local).State = EntityState.Detached;
            }

            Models.Data.Employee? newEmp = await _context.Employees
                .Where(w => w.Id == dbEmp.Id)
                .Include(i => i.Department)
                .AsNoTracking()
                .FirstOrDefaultAsync(ct)
                .ConfigureAwait(false);

            return new EmployeeResponse(Create(newEmp));
        }
        catch (DbUpdateException ex)
        {
            return new EmployeeResponse($"Database update failed: {ex.Message}");
        }
        catch (InvalidOperationException ex)
        {
            return new EmployeeResponse($"Invalid operation: {ex.Message}");
        }
    }

    public async Task<EmployeeResponse> UpdateAsync(int id, EmployeeDto? employee, CancellationToken token)
    {
        if (employee is null)
            return new EmployeeResponse("Can not update null employee");

        if (employee.Id != id)
            return new EmployeeResponse($"Mismatch in id({id}) && id({employee.Id}).");

        if (employee.Id == 0)
            return new EmployeeResponse($"Can not update employee with id({id})");

        if (employee.Department == EmployeeDepartmentEnum.Unknown)
            return new EmployeeResponse("Can not update employee with unknown department");

        return await SaveAsync(employee, token);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Finding department with ID {DepartmentId}")]
    private static partial void LogFindingDepartment(ILogger logger, int departmentId);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Department with ID {DepartmentId} not found")]
    private static partial void LogDepartmentNotFound(ILogger logger, int departmentId);

    [LoggerMessage(Level = LogLevel.Information, Message = "Finding employee with ID {EmployeeId}")]
    private static partial void LogFindingEmployee(ILogger logger, int employeeId);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Employee with ID {EmployeeId} not found")]
    private static partial void LogEmployeeNotFound(ILogger logger, int employeeId);

    [LoggerMessage(Level = LogLevel.Debug, Message = "Employee {EmployeeId} found: {EmployeeName}")]
    private static partial void LogEmployeeFound(ILogger logger, int employeeId, string employeeName);
}
