
using UISampleSpark.Core.Extensions;

namespace UISampleSpark.Core.Repository;

/// <summary>
/// Direct database access repository for employee and department entities.
/// </summary>
/// <remarks>
/// This class provides low-level Entity Framework Core operations on employee data.
/// Prefer using <see cref="IEmployeeService"/> or <see cref="IEmployeeClient"/> 
/// for most application scenarios as they provide DTO conversion and business logic.
/// </remarks>
public class EmployeeDB : IEmployeeDB
{
    private readonly Models.Data.EmployeeContext _context;
    private readonly ILogger<Repository.EmployeeDB> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="EmployeeDB"/> class.
    /// </summary>
    /// <param name="context">The database context for employee data access.</param>
    /// <param name="logger">Logger for structured logging and diagnostics.</param>
    public EmployeeDB(Models.Data.EmployeeContext context, ILogger<Repository.EmployeeDB> logger)
    {
        _context = context;
        _logger = logger;
    }

    private static List<EmployeeDto> Create(List<Models.Data.Employee> list)
    {
        if (list == null) return new List<EmployeeDto>();
        return list.Select(item => Create(item)).OrderBy(x => x.Name).ToList();
    }
    private static List<DepartmentDto> Create(List<Models.Data.Department> list)
    {
        List<DepartmentDto> returnList = new();

        if (list == null) return returnList;

        returnList.AddRange(list.Where(w => !string.IsNullOrEmpty(w?.Name)).Select(item => Create(item)).OrderBy(x => x?.Name).ToList());

        return returnList ?? new List<DepartmentDto>();
    }
    private static DepartmentDto Create(Models.Data.Department item)
    {
        if (item == null)
            throw new ArgumentException("Department can not be null");

        EmployeeDepartmentEnum enumDept = (EmployeeDepartmentEnum)item.Id;

        DepartmentDto dept = new DepartmentDto
        {
            Id = item.Id,
            Name = enumDept.GetDisplayName(),
            Description = enumDept.GetDescription(),
            Employees = item?.Employees?.Select(s => Create(s)).ToArray()
        };

        return dept;
    }

    private static EmployeeDto Create(Models.Data.Employee entity)
    {
        return new EmployeeDto(
            entity.Id,
            entity.Name ?? "DEFAULT",
            entity.Age,
            entity.State ?? "TX",
            entity.Country ?? "USA",
            (EmployeeDepartmentEnum)entity.DepartmentId,
            entity.ProfilePicture ?? "default.jpg",
            (GenderEnum)entity.Gender
        );
    }

    public async Task<bool> DeleteEmployeeAsync(int ID)
    {
        Models.Data.Employee? delEmployee = await _context.Employees.FindAsync(ID).ConfigureAwait(false);
        if (delEmployee is null)
        {
            return false;
        }
        try
        {
            _context.Employees.Remove(delEmployee);
            await _context.SaveChangesAsync().ConfigureAwait(false);

        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.Message);
            throw;
        }
        return true;
    }

    public async Task<DepartmentDto> DepartmentAsync(int id)
    {
        return Create(await _context.Departments.Where(w => w.Id == id).Include(i => i.Employees).FirstOrDefaultAsync().ConfigureAwait(false));
    }

    public async Task<List<DepartmentDto>> DepartmentCollectionAsync()
    {
        try
        {
            List<Models.Data.Department> dbDeptList = await _context.Departments.OrderBy(o => o.Name).ToListAsync().ConfigureAwait(false);
            return Create(dbDeptList);
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.Message);
            throw;
        }
    }

    public async Task<EmployeeDto?> EmployeeAsync(int id)
    {
        Models.Data.Employee? empEntity = await _context.Employees.Where(w => w.Id == id).FirstOrDefaultAsync().ConfigureAwait(false);
        return empEntity is null ? null : Create(empEntity);
    }

    public async Task<List<EmployeeDto>> EmployeeCollectionAsync()
    {
        return Create(await _context.Employees.OrderBy(o => o.Name).ToListAsync().ConfigureAwait(false));
    }

    public async Task<EmployeeDto?> UpdateAsync(EmployeeDto? emp)
    {
        if (emp == null) return null;

        if (emp.Id == 0)
        {
            Models.Data.Employee saveUser = new Models.Data.Employee()
            {
                Name = emp.Name,
                State = emp.State,
                Age = emp.Age,
                Country = emp.Country,
                DepartmentId = (int)emp.Department,
                ProfilePicture = emp.ProfilePicture ?? "default.jpg",
                Gender = (Models.Data.Gender)emp.Gender
            };
            await _context.Employees.AddAsync(saveUser);
            await _context.SaveChangesAsync();
            emp.Id = saveUser.Id;
        }
        else
        {
            Models.Data.Employee? saveUser = await _context.Employees.FindAsync(emp.Id).ConfigureAwait(false);

            if (saveUser != null)
            {
                _context.Attach(saveUser);
                saveUser.Name = emp.Name;
                saveUser.State = emp.State;
                saveUser.Age = emp.Age;
                saveUser.Country = emp.Country;
                saveUser.DepartmentId = (int)emp.Department;
                saveUser.ProfilePicture = emp.ProfilePicture ?? "default.jpg";
                saveUser.LastUpdatedDate = DateTime.Now;
                saveUser.Gender = (Models.Data.Gender)emp.Gender;
                await _context.SaveChangesAsync().ConfigureAwait(false);
            }
            else
            {
                saveUser = new Models.Data.Employee()
                {
                    Id = emp.Id,
                    Name = emp.Name,
                    State = emp.State,
                    Age = emp.Age,
                    Country = emp.Country,
                    DepartmentId = (int)emp.Department,
                    ProfilePicture = emp.ProfilePicture ?? "default.jpg",
                    Gender = (Models.Data.Gender)emp.Gender,
                };
                await _context.Employees.AddAsync(saveUser).ConfigureAwait(false);
                await _context.SaveChangesAsync().ConfigureAwait(false);
                emp.Id = saveUser.Id;

            }
        }
        return await EmployeeAsync(emp.Id).ConfigureAwait(false);
    }

    public async Task<DepartmentDto?> UpdateAsync(DepartmentDto? dept)
    {
        if (dept == null) return null;

        if (dept.Id == 0)
        {
            return null;
        }

        DepartmentDto updateDept = new()
        {
            Id = dept.Id,
            Name = dept.Name,
            Description = dept.Description
        };

        Models.Data.Department? saveDept = await _context.Departments.FindAsync(updateDept.Id).ConfigureAwait(false);
        if (saveDept != null)
        {
            _context.Departments.Attach(saveDept);
            saveDept.Name = string.IsNullOrEmpty(updateDept.Name) ? saveDept.Name : updateDept.Name;
            saveDept.Description = string.IsNullOrEmpty(updateDept.Description) ? saveDept.Description : updateDept.Description;
            await _context.SaveChangesAsync().ConfigureAwait(false);
        }
        else
        {
            Models.Data.Department newDept = new Models.Data.Department()
            {
                Id = updateDept.Id,
                Name = string.IsNullOrEmpty(updateDept.Name) ? "MISSING NAME" : updateDept.Name,
                Description = string.IsNullOrEmpty(updateDept.Description) ? "MISSING DESCRIPTION" : updateDept.Description,
            };
            await _context.Departments.AddAsync(newDept).ConfigureAwait(false);
            await _context.SaveChangesAsync().ConfigureAwait(false);
        }
        return await DepartmentAsync(updateDept.Id).ConfigureAwait(false);
    }
}
