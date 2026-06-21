using System;

namespace UISampleSpark.Core.Tests.Models.Data
{
    [TestClass]
    public class DepartmentTests
    {
        [TestMethod]
        public void TestMethod1()
        {
            // Arrange
            Core.Models.Data.Department department = new Core.Models.Data.Department()
            {
                Name = "Department",
                CreatedBy = "Test",
                Description = "Test",
                Id = 1,
                LastUpdatedBy = "Test",
            };

            // Act


            // Assert
            Assert.IsNotNull(department);
            Assert.AreEqual(department.CreatedDate.Date, DateTime.Now.Date);
        }
    }
}


