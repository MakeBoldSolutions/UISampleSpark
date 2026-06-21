using System;
using System.Threading.Tasks;

namespace UISampleSpark.Core.Tests.Repository
{
    [TestClass]
    public class EmployeeMockTests
    {
        [TestMethod]
        public async Task DepartmentAsync_StateUnderTest_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            int id = 1;

            // Act
            DepartmentDto? result = await employeeMock.DepartmentAsync(id);

            // Assert
            Assert.IsNotNull(result);
        }

        [TestMethod]
        public async Task EmployeeAsync_StateUnderTest_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            int id = 0;

            // Act
            EmployeeDto? result = await employeeMock.EmployeeAsync(id);

            // Assert
            Assert.IsNull(result);
        }
        [TestMethod]
        public async Task Delete_StateUnderTest_Id1()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            int ID = 1;

            // Act
            bool result = await employeeMock.DeleteEmployeeAsync(ID);

            // Assert
            Assert.IsNotNull(result);
        }

        [TestMethod]
        public async Task Delete_StateUnderTest_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            int ID = 0;

            // Act
            bool result = await employeeMock.DeleteEmployeeAsync(ID);

            // Assert
            Assert.IsNotNull(result);
        }

        [TestMethod]
        public async Task DeleteAsync_StateUnderTest_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            int ID = 0;

            // Act
            bool result = await employeeMock.DeleteEmployeeAsync(
                ID);

            // Assert
            Assert.IsNotNull(result);
        }

        [TestMethod]
        public void DepartmentCollection_StateUnderTest_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);

            // Act
            System.Collections.Generic.List<DepartmentDto> result = employeeMock.DepartmentCollection();

            // Assert
            Assert.IsNotNull(result);
        }

        [TestMethod]
        public async Task DepartmentCollectionAsync_StateUnderTest_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);

            // Act
            System.Collections.Generic.List<DepartmentDto> result = await employeeMock.DepartmentCollectionAsync();

            // Assert
            Assert.IsNotNull(result);
        }

        [TestMethod]
        public void EmployeeCollection_StateUnderTest_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);

            // Act
            System.Collections.Generic.List<EmployeeDto> result = employeeMock.EmployeeCollection();

            // Assert
            Assert.IsNotNull(result);
        }

        [TestMethod]
        public async Task EmployeeCollectionAsync_StateUnderTest_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);

            // Act
            System.Collections.Generic.List<EmployeeDto> result = await employeeMock.EmployeeCollectionAsync();

            // Assert
            Assert.IsNotNull(result);
        }
        [TestMethod]
        public async Task UpdateAsync_StateUnderTest_NotFoundID()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            EmployeeDto emp = new(
                9999,
                "Test",
                99,
                "Test",
                "Test",
                EmployeeDepartmentEnum.IT);

            // Act
            EmployeeDto? result = await employeeMock.UpdateAsync(emp);

            // Assert
            Assert.IsNotNull(result);
            Assert.AreEqual(result.Id, 9999);
            Assert.IsTrue(result.IsValid());
        }
        [TestMethod]
        public async Task UpdateAsync_StateUnderTest_NotValid()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            EmployeeDto? emp = null;

            // Act
            EmployeeDto? result = await employeeMock.UpdateAsync(emp);

            // Assert
            Assert.IsNull(result);
        }

        [TestMethod]
        public async Task UpdateAsync_StateUnderTest_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            EmployeeDto? emp = null;

            // Act
            EmployeeDto? result = await employeeMock.UpdateAsync(emp);

            // Assert
            Assert.IsNull(result);
        }

        [TestMethod]
        public async Task UpdateAsync_StateUnderTest_ExpectedBehavior1()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            DepartmentDto? dept = null;

            // Act
            DepartmentDto? result = await employeeMock.UpdateAsync(dept);

            // Assert
            Assert.IsNull(result);
        }


        [TestMethod]
        public async Task Delete_StateUnderTest_ExpectedBehaviorNotFound()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            int ID = 0;

            // Act
            bool result = await employeeMock.DeleteEmployeeAsync(ID);

            // Assert
            Assert.IsNotNull(result);
        }

        [TestMethod]
        public async Task Employee_StateUnderTest_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeDB = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            int id = 0;

            // Act
            EmployeeDto? result = await employeeDB.EmployeeAsync(id);

            // Assert
            Assert.IsNull(result);
        }

        [TestMethod]
        public async Task EmployeeCollection_ExpectedBehavior()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeDB = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);

            // Act
            System.Collections.Generic.List<EmployeeDto> result = await employeeDB.EmployeeCollectionAsync();

            // Assert
            Assert.IsNotNull(result);
        }

        [TestMethod]
        public async Task Update_StateUnderTest_ExpectedBehaviorNewEmployee()
        {
            // Arrange
            Core.Repository.EmployeeMock employeeDB = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            EmployeeDto newEmp = new(
                9999,
                "Test",
                99,
                "Test",
                "Test",
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
            Assert.AreEqual(finalResult?.Age, 44);
            Assert.AreEqual(finalResult?.State, "FL");

        }

        [TestMethod]
        public void EmployeeMock_Constructor_WithGeneratedEmployees()
        {
            // Arrange & Act
            Core.Repository.EmployeeMock mock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance, 20);

            // Assert
            System.Collections.Generic.List<EmployeeDto> employees = mock.EmployeeCollection();
            Assert.IsNotNull(employees);
            Assert.IsTrue(employees.Count >= 20);
        }

        [TestMethod]
        public async Task EmployeeMock_UpdateAsync_NewEmployee_ShouldAdd()
        {
            // Arrange
            Core.Repository.EmployeeMock mock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            int initialCount = mock.EmployeeCollection().Count;

            EmployeeDto newEmp = new EmployeeDto(
                0,
                "New Mock Employee",
                40,
                "Arizona",
                "USA",
                EmployeeDepartmentEnum.IT);

            // Act
            EmployeeDto? result = await mock.UpdateAsync(newEmp);

            // Assert
            Assert.IsNotNull(result);
            Assert.IsTrue(result.Id > 0);
            Assert.AreEqual(initialCount + 1, mock.EmployeeCollection().Count);
        }

        [TestMethod]
        public async Task EmployeeMock_UpdateAsync_NullDepartment_ShouldReturnNull()
        {
            // Arrange
            Core.Repository.EmployeeMock mock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            DepartmentDto? nullDept = null;

            // Act
            DepartmentDto? result = await mock.UpdateAsync(nullDept);

            // Assert
            Assert.IsNull(result);
        }

        [TestMethod]
        public async Task EmployeeMock_DepartmentAsync_InvalidId_ShouldThrowOrReturnNull()
        {
            // Arrange
            Core.Repository.EmployeeMock mock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
            int invalidId = 9999;

            // Act  & Assert - EmployeeMock throws exception for invalid department IDs
            try
            {
                DepartmentDto? result = await mock.DepartmentAsync(invalidId);
                // Some implementations may return null
                Assert.IsNull(result);
            }
            catch (ArgumentException)
            {
                // Expected behavior for invalid ID
                Assert.IsTrue(true);
            }
        }
    }
}


