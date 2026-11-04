namespace UISampleSpark.Core.Tests.Extensions;

// <summary>
/// Defines test class EnumExtensionTests.
/// </summary>
[TestClass]
public class EnumExtensionTests
{
    [TestMethod]
    public void GetDescription_WithEnumValue_ReturnsDescription()
    {
        // Arrange
        TestEnum enumValue = TestEnum.First;

        // Act
        string description = enumValue.GetDescription();

        // Assert
        Assert.AreEqual("The First One", description);
    }
    [TestMethod]
    public void GetDescription_WithEnumValueWithoutDescription_ReturnsEnumValueToString()
    {
        // Arrange
        TestEnum enumValue = TestEnum.Second;

        // Act
        string description = enumValue.GetDescription();

        // Assert
        Assert.AreEqual("Second", description);
    }
    [TestMethod]
    public void GetDescription_WithNullEnum_ReturnsEmptyString()
    {
        // Arrange
        TestEnum? enumValue = null;

        // Act
        string description = enumValue.GetDescription();

        // Assert
        Assert.AreEqual(string.Empty, description);
    }
    [TestMethod]
    public void EnumGetDescription_NullEnum()
    {
        // Arrange
        TestEnum? myTest = null;

        // Act
        string result = myTest.GetDescription();

        // Assert
        Assert.AreEqual(result, string.Empty);
    }
    [TestMethod]
    public void EnumGetDescriptionMissingDisplayName()
    {
        // Arrange
        TestEnum myTest = TestEnum.Second;

        // Act
        string result = myTest.GetDescription();

        // Assert
        Assert.AreEqual(result, "Second");
    }
    [TestMethod]
    public void EnumToDescriptionString_ExpectedBehavior()
    {
        // Arrange
        TestEnum myTest = TestEnum.First;

        // Act
        string result = myTest.GetDescription();

        // Assert
        Assert.AreEqual(result, "The First One");
    }
}
