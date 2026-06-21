using UISampleSpark.Core.Interfaces;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace UISampleSpark.Core.Tests.Services;

/// <summary>
/// 
/// </summary>
[TestClass]
public sealed class EmployeeDatabaseServiceTests : IDisposable
{
    private readonly CancellationToken ct;
    private IEmployeeService? employeeService;
    private Core.Models.Data.EmployeeContext? context;
    private readonly string databaseName;

    public EmployeeDatabaseServiceTests()
    {
        databaseName = $"EmployeeDatabaseServiceTests_{Guid.NewGuid()}";
        ct = default;
    }


    /// <summary>
    /// 
    /// </summary>
    [TestMethod]
    public async Task AddMultiple_StateUnderTest_Null()
    {
        // Arrange
        string?[]? namelist = null;

        // Act
        int result = await employeeService!.AddMultipleEmployeesAsync(namelist);

        // Assert
        Assert.AreEqual(-1, result);
    }

    [TestMethod]
    public async Task AddMultiple_StateUnderTest_Valid()
    {
        // Arrange
        string[] namelist = new string[] { "TestMultiple1", "TestMultiple2", "TestMultiple3" };

        // Act
        PagingParameterModel paging = new PagingParameterModel();
        await employeeService!.AddMultipleEmployeesAsync(namelist).ConfigureAwait(true);
        System.Collections.Generic.IEnumerable<EmployeeDto> empList = await employeeService.GetEmployeesAsync(paging, ct).ConfigureAwait(true);
        EmployeeDto? emp1 = empList.Where(w => w.Name == namelist[0]).FirstOrDefault();

        // Assert
        Assert.IsNotNull(emp1);
        Assert.AreEqual(emp1.Name, namelist[0]);
    }
    [TestMethod]
    public async Task DeleteAsync_ExpectedBehavior()
    {
        // Arrange
        EmployeeDto employee = new EmployeeDto(
            99,
            "TestDelete",
            20,
            "TX",
            "USA",
            EmployeeDepartmentEnum.IT
        );
        employee.Gender = GenderEnum.Male;

        // Act
        EmployeeResponse? result = await employeeService!.SaveAsync(employee, ct);
        int id = result?.Resource?.Id ?? 0;
        EmployeeResponse afterResults = await employeeService.DeleteAsync(id, ct);


        // Assert
        Assert.IsNotNull(result);
        Assert.IsNotNull(afterResults);
        Assert.IsTrue(afterResults.Success);

    }

    [TestMethod]
    public async Task DeleteAsync_StateUnderTest_ExpectedBehavior()
    {
        // Arrange
        int id = 0;

        // Act
        EmployeeResponse result = await employeeService!.DeleteAsync(
            id,
            ct);

        // Assert
        Assert.AreEqual(result.Success, false);
    }

    [TestMethod]
    public async Task FindByIdAsync_StateUnderTest_ExpectedBehavior()
    {
        // Arrange
        int id = 0;

        // Act
        EmployeeResponse result = await employeeService!.FindEmployeeByIdAsync(id, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsFalse(result.Success);
    }

    [TestMethod]
    public async Task Get_StateUnderTest_ExpectedBehavior()
    {
        // Arrange

        // Act
        System.Collections.Generic.IEnumerable<EmployeeDto> result = await employeeService!.GetEmployeesAsync(new PagingParameterModel(), ct);

        // Assert
        Assert.IsNotNull(result);
    }

    [TestMethod]
    public async Task GetAsync_StateUnderTest_ExpectedBehavior()
    {
        // Arrange

        // Act
        System.Collections.Generic.IEnumerable<EmployeeDto> result = await employeeService!.GetEmployeesAsync(new PagingParameterModel(), ct);

        // Assert
        Assert.IsNotNull(result);
    }

    [TestInitialize]
    public async Task Initialize()
    {
        try
        {
            DbContextOptionsBuilder<Core.Models.Data.EmployeeContext> builder = new DbContextOptionsBuilder<Core.Models.Data.EmployeeContext>();
            _ = builder.EnableSensitiveDataLogging(true);
            _ = builder.UseInMemoryDatabase(databaseName);
            context = new Core.Models.Data.EmployeeContext(builder.Options);
            employeeService = new Core.Services.EmployeeDatabaseService(context, NullLogger<Core.Services.EmployeeDatabaseService>.Instance);

            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            foreach (DepartmentDto dept in employeeMock.DepartmentCollection())
            {
                await employeeService.SaveAsync(dept, ct).ConfigureAwait(true);
            }
            foreach (EmployeeDto emp in employeeMock.EmployeeCollection())
            {
                await employeeService.UpdateAsync(emp.Id, emp, ct).ConfigureAwait(true);
            }
        }
        catch (Exception ex)
        {
            Console.Write(ex.Message);
            throw;
        }
    }

    [TestCleanup]
    public void Cleanup()
    {
        context?.Dispose();
    }

    public void Dispose()
    {
        context?.Dispose();
        GC.SuppressFinalize(this);
    }

    [TestMethod]
    public async Task Save_StateUnderTest_ValidNew()
    {
        // Arrange
        EmployeeDto item = new(
            999,
            "Test",
            25,
            "Texas",
            "USA",
            EmployeeDepartmentEnum.IT);

        // Act
        EmployeeResponse result = await employeeService.SaveAsync(item, ct);

        result.Resource.Age = 50;

        EmployeeResponse UpdateResult = await employeeService.SaveAsync(result.Resource, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Success);
        Assert.IsNotNull(result);
        Assert.IsNotNull(UpdateResult);
        Assert.IsTrue(UpdateResult.Success);
        Assert.AreEqual(50, UpdateResult.Resource?.Age);
    }

    [TestMethod]
    public async Task SaveAsync_StateUnderTest_Null()
    {
        // Arrange
        EmployeeDto? item = null;

        // Act
        EmployeeResponse result = await employeeService.SaveAsync(item, ct);

        // Assert
        Assert.IsNotNull(result);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    [TestMethod]
    public async Task SaveAsync_StateUnderTest_Valid()
    {
        // Arrange
        CancellationToken cancellationToken = default;
        EmployeeDto item = new(
            999,
            "Test",
            25,
            "Texas",
            "USA",
            EmployeeDepartmentEnum.IT);

        // Act
        EmployeeResponse result = await employeeService.SaveAsync(item, cancellationToken);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Success);
    }
    [TestMethod]
    public async Task SaveAsync_StateUnderTest_ValidNew()
    {
        // Arrange
        EmployeeDto item = new(
            999,
            "Test",
            25,
            "Texas",
            "USA",
            EmployeeDepartmentEnum.IT);

        // Act
        EmployeeResponse result = await employeeService.SaveAsync(item, ct);
        if (result.Success)
            item = result.Resource;

        EmployeeResponse FindResult = await employeeService.FindEmployeeByIdAsync(item.Id, ct).ConfigureAwait(true);

        if (FindResult.Success)
            item = FindResult.Resource;

        item.Age = 50;

        EmployeeResponse UpdateResult = await employeeService.SaveAsync(item, ct);

        if (UpdateResult.Success)
            item = UpdateResult.Resource;


        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Success);
        Assert.IsNotNull(item);
        Assert.IsNotNull(UpdateResult);
        Assert.IsTrue(UpdateResult.Success);
        Assert.AreEqual(50, UpdateResult.Resource?.Age);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    [TestMethod]
    public async Task UpdateAsync_EmployeeId0()
    {
        // Arrange
        int id = 0;
        EmployeeDto item = new(
            999,
            "Test",
            25,
            "Texas",
            "USA",
            EmployeeDepartmentEnum.IT);

        // Act
        EmployeeResponse result = await employeeService.UpdateAsync(id, item, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsFalse(result.Success);
        Assert.AreEqual("Mismatch in id(0) && id(999).", result.Message);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    [TestMethod]
    public async Task UpdateAsync_LookupEmployeeId99_NoMatch()
    {
        // Arrange
        int id = 999;
        // Act
        EmployeeDto item = new(
            1,
            "Test",
            25,
            "Texas",
            "USA",
            EmployeeDepartmentEnum.IT);

        EmployeeResponse result = await employeeService.UpdateAsync(
            id,
            item,
            ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsFalse(result.Success);
        Assert.AreEqual("Mismatch in id(999) && id(1).", result.Message);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    [TestMethod]
    public async Task UpdateAsync_LookupEmployeeId999_NotFound()
    {
        // Arrange
        int id = 999;
        // Act
        EmployeeDto item = new(
            999,
            "Test",
            25,
            "Texas",
            "USA",
            EmployeeDepartmentEnum.IT);


        EmployeeResponse result = await employeeService.UpdateAsync(
            id,
            item,
            ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Success);
        Assert.AreEqual(string.Empty, result.Message);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    [TestMethod]
    public async Task UpdateAsync_NullEmployeeId99()
    {
        // Arrange
        int id = 99;
        EmployeeDto? employee = null;

        // Act
        EmployeeResponse result = await employeeService.UpdateAsync(
            id,
            employee,
            ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsFalse(result.Success);
        Assert.AreEqual("Can not update null employee", result.Message);
    }
    [TestMethod]
    public async Task UpdateAsync_NullEmployeeIdZero()
    {
        // Arrange
        int id = 0;
        EmployeeDto? employee = null;

        // Act
        EmployeeResponse result = await employeeService!.UpdateAsync(
            id,
            employee,
            ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsFalse(result.Success);
    }

    [TestMethod]
    public async Task GetDepartmentsAsync_WithoutEmployees_ShouldReturnDepartments()
    {
        // Arrange
        bool includeEmployees = false;

        // Act
        System.Collections.Generic.IEnumerable<DepartmentDto> result = await employeeService!.GetDepartmentsAsync(includeEmployees, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Any());
    }

    [TestMethod]
    public async Task GetDepartmentsAsync_WithEmployees_ShouldReturnDepartmentsWithEmployees()
    {
        // Arrange
        bool includeEmployees = true;

        // Act
        System.Collections.Generic.IEnumerable<DepartmentDto> result = await employeeService!.GetDepartmentsAsync(includeEmployees, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Any());
    }

    [TestMethod]
    public async Task FindDepartmentByIdAsync_WithValidId_ShouldReturnDepartment()
    {
        // Arrange
        int deptId = (int)EmployeeDepartmentEnum.IT;

        // Act
        DepartmentDto? result = await employeeService!.FindDepartmentByIdAsync(deptId, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(deptId, result.Id);
    }

    [TestMethod]
    public async Task FindDepartmentByIdAsync_WithInvalidId_ShouldReturnNull()
    {
        // Arrange
        int deptId = 9999;

        // Act
        DepartmentDto? result = await employeeService!.FindDepartmentByIdAsync(deptId, ct);

        // Assert
        Assert.IsNull(result);
    }

    [TestMethod]
    public async Task SaveDepartmentAsync_WithNullDepartment_ShouldReturnError()
    {
        // Arrange
        DepartmentDto? dept = null;

        // Act
        DepartmentResponse result = await employeeService!.SaveAsync(dept!, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsFalse(result.Success);
        Assert.AreEqual("Department can not be null", result.Message);
    }

    [TestMethod]
    public async Task SaveDepartmentAsync_WithZeroId_ShouldReturnError()
    {
        // Arrange
        DepartmentDto dept = new DepartmentDto
        {
            Id = 0,
            Name = "Test",
            Description = "Test"
        };

        // Act
        DepartmentResponse result = await employeeService!.SaveAsync(dept, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsFalse(result.Success);
        Assert.AreEqual("Zero ID not allowed", result.Message);
    }

    [TestMethod]
    public async Task SaveDepartmentAsync_WithValidDepartment_ShouldSaveDepartment()
    {
        // Arrange
        DepartmentDto dept = new DepartmentDto(EmployeeDepartmentEnum.Accounting);

        // Act
        DepartmentResponse result = await employeeService!.SaveAsync(dept, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Success);
        Assert.IsNotNull(result.Resource);
    }

    [TestMethod]
    public async Task SaveEmployeeDbAsync_WithInvalidDepartment_ShouldReturnError()
    {
        // Arrange
        EmployeeDto employee = new EmployeeDto(
            0,
            "Test User",
            25,
            "TX",
            "USA",
            (EmployeeDepartmentEnum)9999);

        // Act
        EmployeeResponse result = await employeeService!.SaveAsync(employee, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsFalse(result.Success);
        Assert.AreEqual("Department not found", result.Message);
    }

    [TestMethod]
    public async Task GetEmployeesAsync_WithNullPaging_ShouldThrowException()
    {
        // Arrange
        PagingParameterModel? paging = null;

        // Act & Assert
        try
        {
            await employeeService!.GetEmployeesAsync(paging!, ct);
            Assert.Fail("Expected ArgumentNullException was not thrown");
        }
        catch (ArgumentNullException)
        {
            // Expected exception
            Assert.IsTrue(true);
        }
    }

    [TestMethod]
    public async Task GetEmployeesAsync_WithPaging_ShouldReturnPagedResults()
    {
        // Arrange
        PagingParameterModel paging = new PagingParameterModel
        {
            PageNumber = 1,
            PageSize = 5
        };

        // Act
        System.Collections.Generic.IEnumerable<EmployeeDto> result = await employeeService!.GetEmployeesAsync(paging, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Count() <= 5);
    }

    [TestMethod]
    public async Task SaveAsync_WithNullDepartmentDto_ShouldReturnError()
    {
        // Arrange
        DepartmentDto? dept = null;

        // Act
        DepartmentResponse result = await employeeService!.SaveAsync(dept!, ct);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsFalse(result.Success);
        Assert.AreEqual("Department can not be null", result.Message);
    }
}


