using System;
using System.Text.Json;
namespace UISampleSpark.Core.Tests.Models;

[TestClass]
public class DepartmentDtoTests
{
    [TestMethod]
    public void DepartmentDto_ConstructWithValidValues_Success()
    {
        // Arrange
        EmployeeDepartmentEnum dept = EmployeeDepartmentEnum.IT;

        // Act
        DepartmentDto department = new DepartmentDto(dept);

        string mytest = department.ToString();

        // Assert
        Assert.AreEqual("Department Id=2, Name=IT", mytest);
        Assert.AreEqual((int)dept, department.Id);
        Assert.AreEqual(dept.ToString(), department.Name);
        Assert.AreEqual(dept.GetDescription(), department.Description);
    }

    [TestMethod]
    public void DepartmentDto_SetValidName_Success()
    {
        // Arrange
        DepartmentDto department = new(EmployeeDepartmentEnum.IT);

        // Act
        string newName = "New Department Name";
        department.Name = newName;

        // Assert
        Assert.AreEqual(newName, department.Name);
    }

    [TestMethod]
    public void DepartmentDto_SetInvalidName_ThrowsArgumentException()
    {
        // Arrange
        DepartmentDto department = new DepartmentDto(EmployeeDepartmentEnum.IT);

        // Act and Assert
        bool exceptionThrown = false;
        try
        {
            department.Name = "   ";
        }
        catch (ArgumentException)
        {
            exceptionThrown = true;
        }
        Assert.IsTrue(exceptionThrown, "Expected ArgumentException was not thrown");
    }

    [TestMethod]
    public void DepartmentDto_ExpectedResults()
    {
        // Arrange
        DepartmentDto departmentDto = new DepartmentDto(EmployeeDepartmentEnum.IT)
        {
            Employees = new EmployeeDto[]
        {
            new EmployeeDto(1,
                "Test",
                22,
                "TX",
                "USA",
                EmployeeDepartmentEnum.IT),
            new EmployeeDto(
                2,
                "Test Two",
                33,
                "TX",
                "USA",
                EmployeeDepartmentEnum.IT)
        },

            // Act
            Name = "Test Name",
            Description = "Test Description"
        };

        // Assert
        Assert.IsNotNull(departmentDto);
        Assert.AreEqual(2, departmentDto.Id);
        Assert.AreEqual("Test Name", departmentDto.Name);
        Assert.AreEqual("Test Description", departmentDto.Description);
        Assert.IsNotNull(departmentDto.Employees);
        Assert.AreEqual(2, departmentDto.Employees.Length);
    }

    [TestMethod]
    public void DepartmentDto_Equality()
    {
        // Arrange
        DepartmentDto dept1 = new DepartmentDto(EmployeeDepartmentEnum.IT);

        DepartmentDto dept1_copy = new DepartmentDto(EmployeeDepartmentEnum.IT);

        bool areEqual = (dept1 == dept1_copy);

        // Assert
        Assert.IsTrue(areEqual);
    }
    [TestMethod]
    public void DepartmentDto_Serialize()
    {
        // Arrange
        DepartmentDto dept1 = new DepartmentDto(EmployeeDepartmentEnum.IT);

        string deptString = JsonSerializer.Serialize(dept1);

        DepartmentDto? dept1_copy = JsonSerializer.Deserialize<DepartmentDto>(deptString);

        bool areEqual = (dept1 == dept1_copy);

        // Assert
        Assert.IsTrue(areEqual);
        Assert.IsNotNull(deptString);

    }
}
