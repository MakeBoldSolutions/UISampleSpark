using SkiaSharp;

namespace UISampleSpark.Core.Tests.Extensions;


[TestClass]
public class ImageExtensionsTests
{
    [TestMethod]
    public void ScaleImage_WhenMaxHeightIsGreaterThanOriginalHeight_ReturnsImageWithProportionalWidth()
    {
        // Arrange
        using var originalImage = new SKBitmap(100, 200);
        int maxHeight = 300;

        // Act
        using var scaledImage = originalImage.ScaleImage(maxHeight);

        // Assert
        Assert.AreEqual(maxHeight, scaledImage.Height);
        Assert.IsTrue(scaledImage.Width >= originalImage.Width);
    }
}
