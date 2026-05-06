namespace UISampleSpark.Core.Tests.Models;

/// <summary>
/// Defines test class EmployeeDtoTests.
/// </summary>
[TestClass]
public class EmployeeDtoTests
{
    [TestMethod]
    public void emp_IsValidFalse_Age()
    {
        // Arrange
        EmployeeDto emp = GetValidEmployee;
        emp.Age = 0;

        // Assert
        Assert.IsNotNull(emp, "Employee should not be null");
        Assert.IsFalse(emp.IsValid(), "Employee with age 0 should be invalid");
    }

    [TestMethod]
    public void emp_IsValidFalse_Country()
    {
        // Arrange
        EmployeeDto emp = GetValidEmployee;
        emp.Country = string.Empty;

        // Assert
        Assert.IsNotNull(emp, "Employee should not be null");
        Assert.IsFalse(emp.IsValid(), "Employee with empty country should be invalid");
    }

    [TestMethod]
    public void emp_IsValidFalse_Department()
    {
        // Arrange
        EmployeeDto emp = GetValidEmployee;
        emp.Department = EmployeeDepartmentEnum.Unknown;

        // Assert
        Assert.IsNotNull(emp, "Employee should not be null");
        Assert.IsFalse(emp.IsValid(), "Employee with unknown department should be invalid");
    }

    [TestMethod]
    public void emp_IsValidFalse_Name()
    {
        // Arrange
        EmployeeDto emp = GetValidEmployee;
        emp.Name = string.Empty;

        // Assert
        Assert.IsNotNull(emp, "Employee should not be null");
        Assert.IsFalse(emp.IsValid(), "Employee with empty name should be invalid");
    }

    [TestMethod]
    public void emp_IsValidFalse_State()
    {
        // Arrange
        EmployeeDto emp = GetValidEmployee;
        emp.State = string.Empty;

        // Assert
        Assert.IsNotNull(emp, "Employee should not be null");
        Assert.IsFalse(emp.IsValid(), "Employee with empty state should be invalid");
    }

    [TestMethod]
    public void emp_Validate()
    {
        // Arrange
        EmployeeDto emp = GetValidEmployee;

        // Assert - Using Assert.Multiple for better reporting
        Assert.IsNotNull(emp, "Employee should not be null");
        Assert.IsTrue(emp.IsValid(), "Employee should be valid");
        Assert.AreEqual("Name", emp.Name, "Employee name should match");
        Assert.AreEqual("State", emp.State, "Employee state should match");
        Assert.AreEqual("Country", emp.Country, "Employee country should match");
        Assert.AreEqual(EmployeeDepartmentEnum.Marketing, emp.Department, "Employee department should match");
        Assert.AreEqual(20, emp.Age, "Employee age should match");
    }

    [TestMethod]
    public void EmployeeDto_Equals_DifferentProperties_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee1 = new(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new(2, "Jane Smith", 25, "New York", "USA", EmployeeDepartmentEnum.Marketing);

        // Act
        bool areEqual = employee1.Equals(employee2);

        // Assert
        Assert.IsFalse(areEqual, "Employees with different properties should not be equal");
    }

    [TestMethod]
    public void EmployeeDto_Equals_SameProperties_ReturnsTrue()
    {
        // Arrange
        EmployeeDto employee1 = new(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool areEqual = employee1.Equals(employee2);

        // Assert
        Assert.IsTrue(areEqual, "Employees with same properties should be equal");
    }

    [TestMethod]
    public void EmployeeDto_InvalidData_IsNotValid()
    {
        // Arrange
        EmployeeDto employee = new()
        {
            Name = string.Empty,
            Age = 0,
            Country = string.Empty,
            Department = EmployeeDepartmentEnum.Unknown,
            Id = 0
        };

        // Act
        bool isValid = employee.IsValid();

        // Assert
        Assert.IsFalse(isValid, "Employee with invalid data should not be valid");
    }

    [TestMethod]
    public void EmployeeDto_InvalidData_IsNotValid_new()
    {
        // Arrange
        EmployeeDto employee = new EmployeeDto();

        // Act
        bool isValid = employee.IsValid();

        // Assert
        Assert.IsFalse(isValid, "New employeedto object should be invalid");
    }

    [TestMethod]
    public void EmployeeDto_InvalidData_ThrowsArgumentException()
    {
        // Arrange
        int id = 1;
        string name = string.Empty; // Invalid empty name
        int age = 30;
        string state = "California";
        string country = "USA";
        EmployeeDepartmentEnum department = EmployeeDepartmentEnum.IT;

        // Act and Assert
        bool exceptionThrown = false;
        try
        {
            _ = new EmployeeDto(id, name, age, state, country, department);
        }
        catch (EmployeeDtoValidationException)
        {
            exceptionThrown = true;
        }
        Assert.IsTrue(exceptionThrown, "Expected EmployeeDtoValidationException was not thrown");
    }


    [TestMethod]
    public void EmployeeDto_ValidData_IsValid()
    {
        // Arrange
        EmployeeDto employee = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool isValid = employee.IsValid();

        // Assert
        Assert.IsTrue(isValid, "Employee with valid data should be valid");
    }
    public static EmployeeDto GetValidEmployee => new EmployeeDto(
                999,
                "Name",
                20,
                "State",
                "Country",
                EmployeeDepartmentEnum.Marketing);


    [TestMethod]
    public void GetHashCode_EqualProperties_ReturnsSameHashCode()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);

        // Act
        int hashCode1 = employee1.GetHashCode();
        int hashCode2 = employee2.GetHashCode();

        // Assert
        Assert.AreEqual(hashCode1, hashCode2, "Hash codes should be the same for equal objects");
    }

    [TestMethod]
    public void GetHashCode_DifferentProperties_ReturnsDifferentHashCode()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(2, "Jane Smith", 25, "New York", "USA", EmployeeDepartmentEnum.Accounting);

        // Act
        int hashCode1 = employee1.GetHashCode();
        int hashCode2 = employee2.GetHashCode();

        // Assert
        Assert.AreNotEqual(hashCode1, hashCode2, "Hash codes should be different for objects with different properties");
    }

    [TestMethod]
    public void Equals_SameInstance_ReturnsTrue()
    {
        // Arrange
        EmployeeDto employee = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);

        // Act
        object sameRef = employee;
        bool result = employee.Equals(sameRef);

        // Assert
        Assert.IsTrue(result, "Same instance should be equal to itself");
    }

    [TestMethod]
    public void Equals_EqualProperties_ReturnsTrue()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee1.Equals(employee2);

        // Assert
        Assert.IsTrue(result, "Employees with equal properties should be equal");
    }

    [TestMethod]
    public void Equals_DifferentProperties_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(2, "Jane Smith", 25, "New York", "USA", EmployeeDepartmentEnum.Accounting);

        // Act
        bool result = employee1.Equals(employee2);

        // Assert
        Assert.IsFalse(result, "Employees with different properties should not be equal");
    }

    [TestMethod]
    public void Equals_NullProperties_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(1, "Jane Smith", 30, "California", "USA", EmployeeDepartmentEnum.IT)
        {
            Name = null
        };

        // Act
        bool result = employee1.Equals(employee2);
        bool result2 = employee2.Equals(employee1);

        // Assert
        Assert.IsFalse(result, "Employees with null properties should not be equal");
        Assert.IsFalse(result2, "Employees with null properties should not be equal");
    }

    [TestMethod]
    public void Equals_NullObject_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = object.Equals(employee, null);

        // Assert
        Assert.IsFalse(result, "Employee should not be equal to null");
    }

    [TestMethod]
    public void Equals_DifferentObjectType_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);
        object otherObject = new object();

        // Act
        bool result = employee.Equals(otherObject);

        // Assert
        Assert.IsFalse(result, "Employee should not be equal to an object of different type");
    }

    [TestMethod]
    public void Equals_BothInstancesNull_ReturnsTrue()
    {
        // Arrange
        EmployeeDto employee1 = null;
        EmployeeDto employee2 = null;

        // Act
        bool result = Equals(employee1, employee2);
        // Assert
        Assert.IsTrue(result, "Two null instances should be considered equal");
    }
    [TestMethod]
    public void Equals_SingleInstanceNull_ReturnsTrue()
    {
        // Arrange
        EmployeeDto? employee1 = null;
        EmployeeDto? sameRef = employee1;

        // Act
        bool result = Equals(employee1, sameRef);
        // Assert
        Assert.IsTrue(result, "A null instance should be considered equal to itself");
    }
    [TestMethod]
    public void Equals_OneInstancesNull_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee = new EmployeeDto(1, "John Doe", 30, "California", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = null;

        // Act
        bool result = employee.Equals(employee2);
        // Assert
        Assert.IsFalse(result, "An employee instance should not be equal to a null instance");
    }

    [TestMethod]
    public void CompareTo_NullObject_Returns1()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto();
        EmployeeDto employee2 = null;

        // Act
        int result = employee1.CompareTo(employee2);

        // Assert
        Assert.AreEqual(1, result, "Comparing with null should return 1");
    }

    [TestMethod]
    public void CompareTo_EqualObjects_Returns0()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        int result = employee1.CompareTo(employee2);

        // Assert
        Assert.AreEqual(0, result, "Comparing equal objects should return 0");
    }

    [TestMethod]
    public void CompareTo_DifferentId_ReturnsNonZero()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(2, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        int result = employee1.CompareTo(employee2);

        // Assert
        Assert.IsTrue(result != 0, "Comparing employees with different IDs should not return 0");
    }

    [TestMethod]
    public void CompareTo_DifferentName_ReturnsNonZero()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(1, "Jane", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        employee2.Name = null;

        // Act
        int result = employee1.CompareTo(employee2);
        int result2 = employee2.CompareTo(employee1);

        // Assert
        Assert.IsTrue(result != 0, "Comparing employees with different names should not return 0");
        Assert.IsTrue(result2 != 0, "Comparing employees with different names should not return 0");
    }

    [TestMethod]
    public void CompareTo_DifferentAge_ReturnsNonZero()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(1, "John", 35, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        int result = employee1.CompareTo(employee2);

        // Assert
        Assert.IsTrue(result != 0, "Comparing employees with different ages should not return 0");
    }

    [TestMethod]
    public void OperatorEquals_EqualObjects_ReturnsTrue()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee1 == employee2;

        // Assert
        Assert.IsTrue(result, "Operator == should return true for equal objects");
    }

    [TestMethod]
    public void OperatorEquals_DifferentObjects_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(2, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee1 == employee2;

        // Assert
        Assert.IsFalse(result, "Operator == should return false for different objects");
    }

    // Similar tests for the remaining operator overloads: !=, <, <=, >, >=

    [TestMethod]
    public void OperatorNotEquals_EqualObjects_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee1 != employee2;

        // Assert
        Assert.IsFalse(result, "Operator != should return false for equal objects");
    }

    [TestMethod]
    public void OperatorNotEquals_DifferentObjects_ReturnsTrue()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(2, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee1 != employee2;

        // Assert
        Assert.IsTrue(result, "Operator != should return true for different objects");
    }

    [TestMethod]
    public void OperatorGreaterThan_GreaterThan_ReturnsTrue()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(2, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee2 > employee1;

        // Assert
        Assert.IsTrue(result, "Operator > should return true if left object is greater");
    }

    [TestMethod]
    public void OperatorGreaterThan_LessThan_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(2, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee1 > employee2;

        // Assert
        Assert.IsFalse(result, "Operator > should return false if left object is less");
    }

    [TestMethod]
    public void OperatorGreaterThan_EqualObjects_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee1 > employee2;

        // Assert
        Assert.IsFalse(result, "Operator > should return false for equal objects");
    }

    // Similar tests for the < (less than), >= (greater than or equal to), <= (less than or equal to) operator overloads

    [TestMethod]
    public void OperatorLessThan_GreaterThan_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(2, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee2 < employee1;

        // Assert
        Assert.IsFalse(result, "Operator < should return false if left object is greater");
    }

    [TestMethod]
    public void OperatorLessThan_LessThan_ReturnsTrue()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(2, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee1 < employee2;

        // Assert
        Assert.IsTrue(result, "Operator < should return true if left object is less");
    }

    [TestMethod]
    public void OperatorLessThan_EqualObjects_ReturnsFalse()
    {
        // Arrange
        EmployeeDto employee1 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);
        EmployeeDto employee2 = new EmployeeDto(1, "John", 30, "CA", "USA", EmployeeDepartmentEnum.IT);

        // Act
        bool result = employee1 < employee2;

        // Assert
        Assert.IsFalse(result, "Operator < should return false for equal objects");
    }


}
