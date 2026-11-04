using SkiaSharp;

namespace UISampleSpark.Core.Extensions
{
    public static class ImageExtensions
    {
        public static SKBitmap ScaleImage(this SKBitmap image, int maxHeight)
        {
            ArgumentNullException.ThrowIfNull(image);
            double ratio = (double)maxHeight / image.Height;

            int newWidth = (int)(image.Width * ratio);
            int newHeight = (int)(image.Height * ratio);

            var scaledImage = image.Resize(new SKImageInfo(newWidth, newHeight), SKSamplingOptions.Default);
            return scaledImage ?? image;
        }
    }
}
