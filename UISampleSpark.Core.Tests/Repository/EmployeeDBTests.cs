using System;
using System.Linq;
using System.Threading.Tasks;

namespace UISampleSpark.Core.Tests.Repository;

[TestClass]
public sealed class EmployeeDBTests : IDisposable
{
    private Core.Repository.EmployeeDB? employeeDB;
    private Core.Models.Data.EmployeeContext? context;
    private readonly string databaseName;

    public EmployeeDBTests()
    {
        databaseName = $"EmployeeDBTests_{Guid.NewGuid()}";
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
            employeeDB = new Core.Repository.EmployeeDB(context, NullLogger<Core.Repository.EmployeeDB>.Instance);

            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            foreach (DepartmentDto dept in employeeMock.DepartmentCollection())
            {
                await employeeDB.UpdateAsync(dept).ConfigureAwait(true);
            }
            foreach (EmployeeDto emp in employeeMock.EmployeeCollection())
            {
                await employeeDB.UpdateAsync(emp).ConfigureAwait(true);
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
    public async Task Department_List_Expected()
    {
        // Arrange

        // Act
        System.Collections.Generic.List<DepartmentDto> result = await employeeDB.DepartmentCollectionAsync();

        // Assert
        Assert.IsNotNull(result);
    }
    [TestMethod]
    public async Task Department_iD1_Expected()
    {
        // Arrange
        int DeptId = 1;
        // Act
        DepartmentDto result = await employeeDB.DepartmentAsync(DeptId);

        // Assert
        Assert.IsNotNull(result);
    }
    [TestMethod]
    public async Task Department_iD1_Update()
    {
        // Arrange
        int DeptId = 1;
        // Act
        DepartmentDto result = await employeeDB.DepartmentAsync(DeptId);

        result.Description = "Test Description";
        result.Name = "Test Name";
        DepartmentDto? result2 = await employeeDB.UpdateAsync(result);
        // Assert
        Assert.IsNotNull(result);
        Assert.IsNotNull(result2);
        Assert.AreEqual(result2.Name, "HR");
        Assert.AreEqual(result2.Description, "HR");
    }
    [TestMethod]
    public async Task Department_Update_Null()
    {
        // Arrange
        DepartmentDto? test = null;
        // Act
        DepartmentDto? result = await employeeDB.UpdateAsync(test);
        // Assert
        Assert.IsNull(result);
    }

    [TestMethod]
    public async Task Department_Update_Id1()
    {
        // Arrange
        DepartmentDto test = new()
        {
            Id = 1,
            Name = "HR",
            Description = "HR"
        };

        // Act
        DepartmentDto? result = await employeeDB.UpdateAsync(test);
        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(result.Id, 1);
        Assert.AreEqual(result.Name, test.Name);
    }
    [TestMethod]
    public async Task Department_Update_MaxPlusOne()
    {
        // Arrange
        System.Collections.Generic.List<DepartmentDto> depts = await employeeDB.DepartmentCollectionAsync();
        DepartmentDto dept = depts.OrderByDescending(d => d.Id).First();

        DepartmentDto? test = new((EmployeeDepartmentEnum)dept.Id);

        // Act
        DepartmentDto? result = await employeeDB.UpdateAsync(test);
        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(result.Id, test.Id);
        Assert.AreEqual(result.Name, test.Name);
        Assert.AreEqual(result.Description, test.Description);
    }

    [TestMethod]
    public async Task Delete_StateUnderTest_ExpectedBehaviorNewEmployee()
    {
        // Arrange
        EmployeeDto newEmp = new EmployeeDto(
            99,
            "Test User",
            33,
            "Texas",
            "USA",
            EmployeeDepartmentEnum.IT);

        // Act
        // Get current count of employees for post-delete comparison
        System.Collections.Generic.List<EmployeeDto> initResult = await employeeDB.EmployeeCollectionAsync();

        // Add New Employee with Update
        EmployeeDto? addResult = await employeeDB.UpdateAsync(newEmp);
        /// Delete the Employee
        bool result = await employeeDB.DeleteEmployeeAsync(addResult.Id);
        // Get result after delete
        System.Collections.Generic.List<EmployeeDto> finalResult = await employeeDB.EmployeeCollectionAsync();

        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(finalResult.Count, initResult.Count);

    }


    [TestMethod]
    public async Task Delete_StateUnderTest_ExpectedBehaviorNotFound()
    {
        // Arrange
        int ID = 0;

        // Act
        bool result = await employeeDB.DeleteEmployeeAsync(ID);

        // Assert
        Assert.IsFalse(result);
    }

    [TestMethod]
    public async Task Employee_StateUnderTest_ExpectedBehavior()
    {
        // Arrange
        int id = 0;

        // Act
        EmployeeDto? result = await employeeDB.EmployeeAsync(id);

        // Assert
        Assert.IsNull(result);
    }

    [TestMethod]
    public async Task EmployeeCollection_StateUnderTest_ExpectedBehavior()
    {
        // Arrange

        // Act
        System.Collections.Generic.List<EmployeeDto> result = await employeeDB.EmployeeCollectionAsync();

        // Assert
        Assert.IsNotNull(result);
    }

    [TestMethod]
    public async Task Update_StateUnderTest_ExpectedBehaviorNewEmployee()
    {
        // Arrange
        EmployeeDto newEmp = new EmployeeDto(
            99,
            "Test User",
            33,
            "Texas",
            "USA",
            EmployeeDepartmentEnum.IT);

        // Act
        // Add New Employee with Update
        EmployeeDto? addResult = await employeeDB.UpdateAsync(newEmp);
        /// Update the Employee
        addResult.Name = "Test User 2";
        addResult.Age = 44;
        addResult.State = "FL";
        addResult.Department = EmployeeDepartmentEnum.Accounting;
        EmployeeDto? result = await employeeDB.UpdateAsync(addResult);
        // Get result after update
        EmployeeDto? finalResult = await employeeDB.EmployeeAsync(result.Id);

        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(addResult.Id, result.Id);
        Assert.AreEqual(finalResult.Age, 44);
        Assert.AreEqual(finalResult.State, "FL");

    }
    /// <summary>
    /// 
    /// </summary>
    [TestMethod]
    public async Task Update_NewEmployee()
    {
        // Arrange
        EmployeeDto emp = new EmployeeDto(
            99,
            "Test User",
            33,
            "Texas",
            "USA",
            EmployeeDepartmentEnum.IT);

        // Act
        EmployeeDto? result = await employeeDB.UpdateAsync(emp);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Id > 0);
    }
    /// <summary>
    /// 
    /// </summary>
    [TestMethod]
    public async Task Update_NewEmployeeWithId98()
    {
        // Arrange
        EmployeeDto emp = new EmployeeDto(
            98,
            "Test User",
            33,
            "Texas",
            "USA",
            EmployeeDepartmentEnum.IT);


        // Act
        EmployeeDto? result = await employeeDB.UpdateAsync(emp);

        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(98, result.Id);
    }

    [TestMethod]
    public async Task Update_NullEmployee()
    {
        // Arrange
        EmployeeDto? emp = null;

        // Act
        EmployeeDto? result = await employeeDB!.UpdateAsync(emp);

        // Assert
        Assert.IsNull(result);
    }

    [TestMethod]
    public async Task DepartmentAsync_WithInvalidId_ShouldThrowException()
    {
        // Arrange
        int invalidId = 9999;

        // Act & Assert
        try
        {
            await employeeDB!.DepartmentAsync(invalidId);
            Assert.Fail("Expected ArgumentException was not thrown");
        }
        catch (ArgumentException)
        {
            // Expected exception
            Assert.IsTrue(true);
        }
    }

    [TestMethod]
    public async Task DepartmentCollectionAsync_ShouldReturnOrderedList()
    {
        // Arrange & Act
        System.Collections.Generic.List<DepartmentDto> result = await employeeDB!.DepartmentCollectionAsync();

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Count > 0);
        for (int i = 1; i < result.Count; i++)
        {
            Assert.IsTrue(string.Compare(result[i - 1].Name, result[i].Name, StringComparison.Ordinal) <= 0);
        }
    }

    [TestMethod]
    public async Task EmployeeCollectionAsync_ShouldReturnOrderedList()
    {
        // Arrange & Act
        System.Collections.Generic.List<EmployeeDto> result = await employeeDB!.EmployeeCollectionAsync();

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Count > 0);
        for (int i = 1; i < result.Count; i++)
        {
            Assert.IsTrue(string.Compare(result[i - 1].Name, result[i].Name, StringComparison.Ordinal) <= 0);
        }
    }

    [TestMethod]
    public async Task DeleteEmployeeAsync_WithInvalidId_ShouldReturnFalse()
    {
        // Arrange
        int invalidId = -1;

        // Act
        bool result = await employeeDB!.DeleteEmployeeAsync(invalidId);

        // Assert
        Assert.IsFalse(result);
    }

    [TestMethod]
    public async Task UpdateAsync_Employee_WithExistingId_ShouldUpdate()
    {
        // Arrange
        System.Collections.Generic.List<EmployeeDto> employees = await employeeDB!.EmployeeCollectionAsync();
        EmployeeDto existingEmployee = employees.First();
        int originalId = existingEmployee.Id;
        string newName = "Updated Name " + Guid.NewGuid();

        existingEmployee.Name = newName;

        // Act
        EmployeeDto? result = await employeeDB.UpdateAsync(existingEmployee);

        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(originalId, result.Id);
        Assert.AreEqual(newName, result.Name);
    }

    [TestMethod]
    public async Task UpdateAsync_Department_WithNewDepartment_ShouldCreate()
    {
        // Arrange
        DepartmentDto newDept = new DepartmentDto(EmployeeDepartmentEnum.Accounting);

        // Act
        DepartmentDto? result = await employeeDB!.UpdateAsync(newDept);

        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual((int)EmployeeDepartmentEnum.Accounting, result.Id);
        Assert.AreEqual(EmployeeDepartmentEnum.Accounting.ToString(), result.Name);
    }

    [TestMethod]
    public async Task UpdateAsync_Department_WithZeroId_ShouldReturnNull()
    {
        // Arrange
        DepartmentDto dept = new DepartmentDto
        {
            Id = 0,
            Name = "Invalid",
            Description = "Invalid"
        };

        // Act
        DepartmentDto? result = await employeeDB!.UpdateAsync(dept);

        // Assert
        Assert.IsNull(result);
    }

    [TestMethod]
    public async Task UpdateAsync_Employee_CompleteDataUpdate()
    {
        // Arrange
        EmployeeDto newEmp = new EmployeeDto(
            0,
            "Complete Test User",
            28,
            "California",
            "USA",
            EmployeeDepartmentEnum.Marketing);
        newEmp.ProfilePicture = "test.jpg";
        newEmp.Gender = GenderEnum.Female;

        // Act
        EmployeeDto? result = await employeeDB!.UpdateAsync(newEmp);

        // Assert
        Assert.IsNotNull(result);
        Assert.IsTrue(result.Id > 0);
        Assert.AreEqual("Complete Test User", result.Name);
        Assert.AreEqual(28, result.Age);
        Assert.AreEqual("California", result.State);
        Assert.AreEqual(EmployeeDepartmentEnum.Marketing, result.Department);
        Assert.AreEqual(GenderEnum.Female, result.Gender);
    }

    [TestMethod]
    public async Task EmployeeAsync_WithInvalidId_ShouldReturnNull()
    {
        // Arrange
        int invalidId = -999;

        // Act
        EmployeeDto? result = await employeeDB!.EmployeeAsync(invalidId);

        // Assert
        Assert.IsNull(result);
    }

    [TestMethod]
    public async Task UpdateAsync_Department_WithValidUpdate_ShouldUpdate()
    {
        // Arrange
        System.Collections.Generic.List<DepartmentDto> depts = await employeeDB!.DepartmentCollectionAsync();
        DepartmentDto existingDept = depts.First();
        string newDescription = "Updated Description " + Guid.NewGuid();

        DepartmentDto updateDept = new DepartmentDto(EmployeeDepartmentEnum.IT)
        {
            Id = existingDept.Id,
            Description = newDescription
        };

        // Act
        DepartmentDto? result = await employeeDB.UpdateAsync(updateDept);

        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(existingDept.Id, result.Id);
    }
}


