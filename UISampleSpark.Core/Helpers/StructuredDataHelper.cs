using System.Text.Json;
using UISampleSpark.Core.Models;

namespace UISampleSpark.Core.Helpers;

/// <summary>
/// Helper class for generating structured data (JSON-LD) markup
/// </summary>
public static class StructuredDataHelper
{
    /// <summary>
    /// Generate Organization schema for the website
    /// </summary>
    public static string GenerateOrganizationSchema(string baseUrl)
    {
        var organization = new
        {
            context = "https://schema.org",
            type = "Organization",
            name = "UI Sample Spark",
            description = "A .NET web application exploring multiple front-end technologies and UI patterns for building modern web interfaces.",
            url = baseUrl,
            logo = new
            {
                type = "ImageObject",
                url = $"{baseUrl}/favicon.svg"
            },
            sameAs = new[]
            {
                "https://github.com/markhazleton/UISampleSpark",
                "https://markhazleton.com"
            },
            contactPoint = new
            {
                type = "ContactPoint",
                contactType = "Technical Support",
                url = "https://github.com/markhazleton/UISampleSpark/issues"
            }
        };

        return JsonSerializer.Serialize(organization, new JsonSerializerOptions { WriteIndented = true });
    }

    /// <summary>
    /// Generate WebSite schema for search functionality
    /// </summary>
    public static string GenerateWebSiteSchema(string baseUrl)
    {
        var website = new
        {
            context = "https://schema.org",
            type = "WebSite",
            name = "UI Sample Spark",
            description = "Explore multiple front-end UI patterns for .NET web applications including MVC, Razor Pages, React, Vue, htmx, and Blazor.",
            url = baseUrl,
            potentialAction = new
            {
                type = "SearchAction",
                target = new
                {
                    type = "EntryPoint",
                    urlTemplate = $"{baseUrl}/search?q={{search_term_string}}"
                },
                queryInput = "required name=search_term_string"
            }
        };

        return JsonSerializer.Serialize(website, new JsonSerializerOptions { WriteIndented = true });
    }

    /// <summary>
    /// Generate Employee Person schema
    /// </summary>
    public static string GenerateEmployeeSchema(EmployeeDto employee, string baseUrl)
    {
        ArgumentNullException.ThrowIfNull(employee);
        var person = new
        {
            context = "https://schema.org",
            type = "Person",
            name = employee.Name,
            jobTitle = "Employee",
            gender = employee.GenderName,
            workLocation = new
            {
                type = "Place",
                address = new
                {
                    type = "PostalAddress",
                    addressRegion = employee.State,
                    addressCountry = employee.Country
                }
            },
            worksFor = new
            {
                type = "Organization",
                name = "UI Sample Spark",
                department = new
                {
                    type = "Organization",
                    name = employee.DepartmentName
                }
            },
            image = employee.ProfilePicture != null ? $"{baseUrl}/images/{employee.ProfilePicture}" : null,
            identifier = new
            {
                type = "PropertyValue",
                name = "Employee ID",
                value = employee.Id.ToString()
            }
        };

        return JsonSerializer.Serialize(person, new JsonSerializerOptions { WriteIndented = true, DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull });
    }

    /// <summary>
    /// Generate Tutorial/HowTo schema for learning pages
    /// </summary>
    public static string GenerateTutorialSchema(string title, string description, string baseUrl, string currentUrl)
    {
        var tutorial = new
        {
            context = "https://schema.org",
            type = "HowTo",
            name = title,
            description = description,
            image = $"{baseUrl}/favicon.svg",
            totalTime = "PT30M",
            estimatedCost = new
            {
                type = "MonetaryAmount",
                currency = "USD",
                value = "0"
            },
            supply = new[]
            {
                new
                {
                    type = "HowToSupply",
                    name = "Visual Studio or VS Code"
                },
                new
                {
                    type = "HowToSupply",
                    name = ".NET 10 SDK"
                }
            },
            tool = new[]
            {
                new
                {
                    type = "HowToTool",
                    name = "ASP.NET Core Framework"
                }
            },
            step = new[]
            {
                new
                {
                    type = "HowToStep",
                    name = "Explore the UI Patterns",
                    text = "Navigate through different front-end approaches including MVC, Razor Pages, React, Vue, htmx, and Blazor.",
                    url = currentUrl
                }
            }
        };

        return JsonSerializer.Serialize(tutorial, new JsonSerializerOptions { WriteIndented = true });
    }

    /// <summary>
    /// Generate BreadcrumbList schema
    /// </summary>
    public static string GenerateBreadcrumbSchema(List<(string Name, string Url)> breadcrumbs, string baseUrl)
    {
        var breadcrumbList = new
        {
            context = "https://schema.org",
            type = "BreadcrumbList",
            itemListElement = breadcrumbs.Select((breadcrumb, index) => new
            {
                type = "ListItem",
                position = index + 1,
                name = breadcrumb.Name,
                item = breadcrumb.Url.StartsWith("http") ? breadcrumb.Url : $"{baseUrl}{breadcrumb.Url}"
            }).ToArray()
        };

        return JsonSerializer.Serialize(breadcrumbList, new JsonSerializerOptions { WriteIndented = true });
    }

    /// <summary>
    /// Generate SoftwareApplication schema for the demo application
    /// </summary>
    public static string GenerateSoftwareApplicationSchema(string baseUrl)
    {
        var application = new
        {
            context = "https://schema.org",
            type = "SoftwareApplication",
            name = "UI Sample Spark Application",
            description = "A .NET web application showcasing multiple front-end UI patterns, Docker containerization, and modern web development practices.",
            url = baseUrl,
            applicationCategory = "DeveloperApplication",
            operatingSystem = "Web Browser",
            offers = new
            {
                type = "Offer",
                price = "0",
                priceCurrency = "USD"
            },
            author = new
            {
                type = "Person",
                name = "Mark Hazleton",
                url = "https://markhazleton.com"
            },
            programmingLanguage = new[]
            {
                "C#",
                "JavaScript",
                "HTML",
                "CSS"
            },
            runtimePlatform = new[]
            {
                "ASP.NET Core",
                ".NET 10"
            }
        };

        return JsonSerializer.Serialize(application, new JsonSerializerOptions { WriteIndented = true });
    }
}
