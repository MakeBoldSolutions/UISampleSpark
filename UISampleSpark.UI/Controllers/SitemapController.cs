using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using Microsoft.AspNetCore.Mvc.Routing;
using System.Text;
using System.Xml;

namespace UISampleSpark.UI.Controllers;

/// <summary>
/// Controller for generating XML sitemap with dynamic route discovery
/// </summary>
public class SitemapController : Controller
{
    private readonly ILogger<SitemapController> _logger;
    private readonly IActionDescriptorCollectionProvider _actionDescriptorCollectionProvider;
    private readonly IUrlHelperFactory _urlHelperFactory;

    /// <summary>
    /// Initializes a new instance of the SitemapController
    /// </summary>
    /// <param name="logger">Logger for the controller</param>
    /// <param name="actionDescriptorCollectionProvider">Service to get all available actions</param>
    /// <param name="urlHelperFactory">Factory to create URL helpers</param>
    public SitemapController(
        ILogger<SitemapController> logger,
        IActionDescriptorCollectionProvider actionDescriptorCollectionProvider,
        IUrlHelperFactory urlHelperFactory)
    {
        _logger = logger;
        _actionDescriptorCollectionProvider = actionDescriptorCollectionProvider;
        _urlHelperFactory = urlHelperFactory;
    }

    /// <summary>
    /// Generates and returns XML sitemap
    /// </summary>
    /// <returns>XML sitemap content</returns>
    [HttpGet]
    [Route("sitemap.xml")]
    public IActionResult Index()
    {
        try
        {
            var sitemap = GenerateSitemap();
            return Content(sitemap, "application/xml", Encoding.UTF8);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogError(ex, "Error generating sitemap: invalid operation");
            return StatusCode(500, "Error generating sitemap");
        }
        catch (System.Xml.XmlException ex)
        {
            _logger.LogError(ex, "Error generating sitemap: XML error");
            return StatusCode(500, "Error generating sitemap");
        }
    }

    /// <summary>
    /// Generates the XML sitemap content with dynamic route discovery
    /// </summary>
    /// <returns>XML sitemap as string</returns>
    private string GenerateSitemap()
    {
        var baseUrl = $"{Request.Scheme}://{Request.Host}";
        var now = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");

        // Get all discovered routes
        var discoveredRoutes = GetDiscoveredRoutes(baseUrl, now);

        // Define static routes with priorities
        var staticRoutes = GetStaticRoutes(baseUrl, now);

        // Combine and deduplicate routes
        var allRoutes = discoveredRoutes.Concat(staticRoutes)
            .GroupBy(r => r.Url.ToLowerInvariant())
            .Select(g => g.First())
            .OrderByDescending(r => decimal.Parse(r.Priority))
            .ThenBy(r => r.Url)
            .ToList();

        // Build XML sitemap using StringBuilder for better control
        var xml = new StringBuilder();
        xml.AppendLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        xml.AppendLine("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">");

        // Add each URL to the sitemap
        foreach (var route in allRoutes)
        {
            xml.AppendLine("  <url>");
            xml.AppendLine($"    <loc>{System.Net.WebUtility.HtmlEncode(route.Url)}</loc>");
            xml.AppendLine($"    <lastmod>{route.LastMod}</lastmod>");
            xml.AppendLine($"    <changefreq>{route.ChangeFreq}</changefreq>");
            xml.AppendLine($"    <priority>{route.Priority}</priority>");
            xml.AppendLine("  </url>");
        }

        xml.AppendLine("</urlset>");
        return xml.ToString();
    }

    /// <summary>
    /// Discovers routes dynamically from the application
    /// </summary>
    private List<SitemapUrl> GetDiscoveredRoutes(string baseUrl, string now)
    {
        var routes = new List<SitemapUrl>();
        var urlHelper = _urlHelperFactory.GetUrlHelper(ControllerContext);

        var actionDescriptors = _actionDescriptorCollectionProvider.ActionDescriptors.Items
            .Where(ad => ad.AttributeRouteInfo == null) // MVC routes
            .Where(ad => ad.RouteValues.ContainsKey("controller"))
            .Where(ad => ad.RouteValues.ContainsKey("action"))
            .Where(ad => !IsExcludedController(ad.RouteValues["controller"]))
            .Where(ad => !IsExcludedAction(ad.RouteValues["action"]))
            .ToList();

        foreach (var actionDescriptor in actionDescriptors)
        {
            try
            {
                var controller = actionDescriptor.RouteValues["controller"];
                var action = actionDescriptor.RouteValues["action"];

                var url = urlHelper.Action(action, controller);
                if (!string.IsNullOrEmpty(url))
                {
                    var fullUrl = $"{baseUrl}{url}";
                    var routeInfo = GetRouteInfo(controller, action);

                    routes.Add(new SitemapUrl
                    {
                        Url = fullUrl,
                        Priority = routeInfo.Priority,
                        ChangeFreq = routeInfo.ChangeFreq,
                        LastMod = now
                    });
                }
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogWarning(ex, "Could not generate URL for {Controller}/{Action}",
                    actionDescriptor.RouteValues["controller"],
                    actionDescriptor.RouteValues["action"]);
            }
        }

        return routes;
    }

    /// <summary>
    /// Gets static routes that should always be included
    /// </summary>
    private List<SitemapUrl> GetStaticRoutes(string baseUrl, string now)
    {
        return new List<SitemapUrl>
        {
            // Home page variations
            new SitemapUrl { Url = baseUrl, Priority = "1.0", ChangeFreq = "weekly", LastMod = now },
            new SitemapUrl { Url = $"{baseUrl}/", Priority = "1.0", ChangeFreq = "weekly", LastMod = now },
            
            // Razor Pages
            new SitemapUrl { Url = $"{baseUrl}/EmployeeRazor", Priority = "0.8", ChangeFreq = "daily", LastMod = now },
        };
    }

    /// <summary>
    /// Determines if a controller should be excluded from sitemap
    /// </summary>
    private bool IsExcludedController(string? controller)
    {
        if (string.IsNullOrEmpty(controller)) return true;

        var excludedControllers = new[] { "Sitemap", "Api", "Error" };
        return excludedControllers.Contains(controller, StringComparer.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Determines if an action should be excluded from sitemap
    /// </summary>
    private bool IsExcludedAction(string? action)
    {
        if (string.IsNullOrEmpty(action)) return true;

        var excludedActions = new[]
        {
            "Create",
            "Delete",
            "DeleteConfirm",
            "Edit",
            "GetEmployeeDelete",
            "GetEmployeeEdit",
            "GetEmployeeList",
            "Privacy",
            "Save",
            "Table"
        };
        return excludedActions.Contains(action, StringComparer.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Gets route information (priority and change frequency) based on controller and action
    /// </summary>
    private (string Priority, string ChangeFreq) GetRouteInfo(string? controller, string? action)
    {
        return (controller?.ToLowerInvariant(), action?.ToLowerInvariant()) switch
        {
            ("home", "index") => ("1.0", "weekly"),
            ("home", _) => ("0.9", "weekly"),
            ("employee", "index") => ("0.8", "daily"),
            ("employee", "create") => ("0.6", "monthly"),
            ("mvcemployee", "index") => ("0.8", "daily"),
            ("mvcemployee", "create") => ("0.6", "monthly"),
            ("employeesinglepag", _) => ("0.8", "daily"),
            ("employeepivot", _) => ("0.7", "weekly"),
            _ => ("0.5", "monthly")
        };
    }

    /// <summary>
    /// Represents a URL in the sitemap
    /// </summary>
    private class SitemapUrl
    {
        public string Url { get; set; } = string.Empty;
        public string LastMod { get; set; } = string.Empty;
        public string ChangeFreq { get; set; } = string.Empty;
        public string Priority { get; set; } = string.Empty;
    }
}
