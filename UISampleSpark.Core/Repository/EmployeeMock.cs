using Bogus;

namespace UISampleSpark.Core.Repository;
/// <summary>
/// Mock employee repository with generated test data using Bogus library.
/// </summary>
/// <remarks>
/// This implementation generates fake employee data for testing and demonstration purposes.
/// Uses the Bogus library to create realistic employee records with random data.
/// <para>
/// <b>Note:</b> Data is regenerated on each instantiation and is not persisted.
/// </para>
/// </remarks>
public class EmployeeMock : IEmployeeDB
{
    private readonly List<DepartmentDto> _departmentList = new();
    private readonly List<EmployeeDto> _employeeList = new();
    private readonly int _generatedEmployeeCount = 0;
    private readonly ILogger<Repository.EmployeeMock> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="EmployeeMock"/> class.
    /// </summary>
    /// <param name="logger">Logger for structured logging and diagnostics.</param>
    /// <param name="GeneratedEmployeeCount">Number of additional random employees to generate beyond the fixed list.</param>
    public EmployeeMock(ILogger<Repository.EmployeeMock> logger, int GeneratedEmployeeCount = 0)
    {
        _logger = logger;
        _generatedEmployeeCount = GeneratedEmployeeCount;
        _departmentList.AddRange(GetDepartmentList());
        _employeeList.AddRange(GetFullEmployeeList(_generatedEmployeeCount));
    }

    private static List<EmployeeDto> GetFullEmployeeList(int generateCount)
    {
        List<EmployeeDto> list = new List<EmployeeDto>();
        List<Models.Data.Employee> FixedEmployees = new List<Models.Data.Employee>()
            {
            new Models.Data.Employee() { Name = "Ilsa Lund", Age = 25, Country = "USA", Gender=Models.Data.Gender.Female, DepartmentId = (int)EmployeeDepartmentEnum.IT, State = "Kansas" },
            new Models.Data.Employee() { Name = "Major Strasser", Age = 35, Country = "USA",Gender=Models.Data.Gender.Male, DepartmentId = (int)EmployeeDepartmentEnum.IT, State = "Texas" },
            new Models.Data.Employee() { Name = "Rick Blaine", Age = 45, Country = "USA",Gender=Models.Data.Gender.Male, DepartmentId = (int)EmployeeDepartmentEnum.IT, State = "New York" },
            new Models.Data.Employee() { Name = "Victor Laszlo", Age = 55, Country = "USA",Gender=Models.Data.Gender.Male, DepartmentId = (int)EmployeeDepartmentEnum.IT, State = "Colorado" },
            new Models.Data.Employee() { Name = "Louis Renault", Age = 65, Country = "USA",Gender=Models.Data.Gender.Male, DepartmentId = (int)EmployeeDepartmentEnum.IT, State = "Idaho" },
            new Models.Data.Employee() { Name = "Sam Spade", Age = 55, Country = "USA",Gender=Models.Data.Gender.Male, DepartmentId = (int)EmployeeDepartmentEnum.IT, State = "California" },
            new Models.Data.Employee() { Name = "Jim Smith",Age = 35,Gender=Models.Data.Gender.Male,DepartmentId = (int)EmployeeDepartmentEnum.IT,State = "Florida",Country = "USA"},
            new Models.Data.Employee() { Name = "Bob Roberts",Age = 50,Gender=Models.Data.Gender.Male,DepartmentId = (int)EmployeeDepartmentEnum.HR,State = "Texas",Country = "USA"},
            new Models.Data.Employee() { Name = "Sam Malone",Age = 53,Gender=Models.Data.Gender.Male,DepartmentId = (int)EmployeeDepartmentEnum.Marketing,State = "Massachusetts",Country = "USA"},
            new Models.Data.Employee() { Name = "Frank Sinatra",Age = 50,Gender=Models.Data.Gender.Male,DepartmentId = (int)EmployeeDepartmentEnum.Executive,State = "New York",Country = "USA"},
            };
        FixedEmployees.AddRange(GetFakerEmployeeList(generateCount));
        for (int i = 1; i < FixedEmployees.Count; i++)
        {
            try
            {
                EmployeeDto? emp = Create(FixedEmployees[i], i);
                if (emp is not null) list.Add(emp);
            }
            catch (InvalidCastException ex)
            {
                Console.WriteLine($"Invalid cast when creating employee: {ex.Message}");
            }
            catch (ArgumentException ex)
            {
                Console.WriteLine($"Invalid argument when creating employee: {ex.Message}");
            }
        }
        return list;
    }

    private static List<DepartmentDto> GetDepartmentList()
    {
        List<DepartmentDto> list = new List<DepartmentDto>();
        foreach (EmployeeDepartmentEnum dept in Enum.GetValues(typeof(EmployeeDepartmentEnum)))
        {
            if ((int)dept > 0)
            {
                bool doesExists = list.Where(w => w.Id == (int)dept).Any();
                if (!doesExists)
                    list.Add(new DepartmentDto(dept));
            }
        }
        return list;
    }

    private static EmployeeDto? Create(Models.Data.Employee? item, int id)
    {
        if (item == null) return null;
        EmployeeDepartmentEnum empDept = (EmployeeDepartmentEnum)item.DepartmentId;

        return new EmployeeDto(
            id,
            item.Name ?? string.Empty,
            item.Age,
            item.State ?? string.Empty,
            item.Country ?? string.Empty,
            empDept,
            item.ProfilePicture ?? "default.jpg",
            gender: GetGenderEnum(item.Gender)
            );
    }


    private static GenderEnum GetGenderEnum(Models.Data.Gender? gender)
    {
        return gender.HasValue ? (GenderEnum)(int)gender.Value : GenderEnum.Other;
    }

    /// <summary>
    /// Method for Deleting an Employee
    /// </summary>
    /// <param name="ID">The identifier.</param>
    /// <returns><c>true</c> if XXXX, <c>false</c> otherwise.</returns>
    public async Task<bool> DeleteEmployeeAsync(int ID)
    {
        bool bReturn = false;
        await Task.Run(() =>
        {
            EmployeeDto? myEmp = _employeeList.Where(w => w.Id == ID).FirstOrDefault();
            if (myEmp != null)
                bReturn = _employeeList.Remove(myEmp);
        });
        return bReturn;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="id"></param>
    /// <returns></returns>
    public async Task<DepartmentDto?> DepartmentAsync(int id)
    {
        DepartmentDto? department = null;
        await Task.Run(() =>
        {
            department = _departmentList?.Where(w => w.Id == id).FirstOrDefault();
        });
        return department;
    }


    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    public List<DepartmentDto> DepartmentCollection() { return _departmentList; }

    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    public async Task<List<DepartmentDto>> DepartmentCollectionAsync()
    {

        List<DepartmentDto> list = new List<DepartmentDto>();
        await Task.Run(() =>
        {
            list.AddRange(_departmentList);
        });
        return list;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="id"></param>
    /// <returns></returns>
    /// <exception cref="NotImplementedException"></exception>
    public async Task<EmployeeDto?> EmployeeAsync(int id)
    {
        EmployeeDto? emp = null;
        await Task.Run(() =>
        {
            emp = _employeeList?.Where(w => w.Id == id).FirstOrDefault() ?? null;
        });
        return emp;
    }

    //Return list of all Employees
    /// <summary>
    /// Employees the collection.
    /// </summary>
    /// <returns>List&lt;EmployeeModel&gt;.</returns>
    public List<EmployeeDto> EmployeeCollection() { return _employeeList; }

    public async Task<List<EmployeeDto>> EmployeeCollectionAsync()
    {
        List<EmployeeDto> list = new List<EmployeeDto>();
        await Task.Run(() =>
        {
            list.AddRange(_employeeList);
        });
        return list;
    }

    public static List<Models.Data.Employee> GetFakerEmployeeList(int generateCount)
    {
        string[] states = ["Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"];
        
        Faker<Models.Data.Employee> fakeEmployees = new Faker<Models.Data.Employee>()
            .CustomInstantiator(f => new Models.Data.Employee { Name = "Default" })
            .RuleFor(u => u.Gender, f => f.PickRandom<Models.Data.Gender>())
            .RuleFor(u => u.Name, (f, u) => f.Name.FullName((Bogus.DataSets.Name.Gender)u.Gender))
            .RuleFor(u => u.Age, f => f.Random.Number(18, 70))
            .RuleFor(u => u.DepartmentId, f => f.Random.Number(1, 6))
            .RuleFor(u => u.Country, "USA")
            .RuleFor(u => u.State, f => f.Random.ListItem(states))
            .FinishWith((f, u) => { });

        return fakeEmployees.Generate(generateCount);
    }
    //Method for Updating Employee record
    /// <summary>
    /// Updates the specified emp.
    /// </summary>
    /// <param name="emp">The emp.</param>
    /// <returns>EmployeeModel.</returns>
    public async Task<EmployeeDto?> UpdateAsync(EmployeeDto? emp)
    {
        if (emp == null)
            return null;

        if (!emp.IsValid())
            return emp;

        if (emp.Id == 0)
        {
            await Task.Run(() =>
            {
                int nextID = _employeeList.OrderByDescending(o => o.Id).Select(s => s.Id).FirstOrDefault() + 1;
                emp.Id = nextID;
                _employeeList.Add(emp);
            });
            return emp;
        }
        else
        {
            EmployeeDto? updateEmp = _employeeList.Find(o => o.Id == emp.Id);
            if (updateEmp == null)
            {
                _employeeList.Add(emp);
            }
            else
            {
                updateEmp.Name = emp.Name;
                updateEmp.Age = emp.Age;
                updateEmp.Department = emp.Department;
                updateEmp.Country = emp.Country;
                updateEmp.State = emp.State;
                updateEmp.ProfilePicture = emp.ProfilePicture;
            }
            return emp;
        }
    }

    /// <summary>
    /// Update Department 
    /// </summary>
    /// <param name="dept"></param>
    /// <returns></returns>
    public async Task<DepartmentDto?> UpdateAsync(DepartmentDto? dept)
    {
        await Task.Run(() =>
        {
            // Mock implementation: returns dept unchanged (no persistent store)
        });
        return dept;
    }
}
