namespace UISampleSpark.UI.Controllers
{
    /// <summary>
    /// Single Page Application (SPA) Controller
    /// </summary>
    /// <remarks>
    /// This controller demonstrates a modern approach to building single-page applications
    /// using client-side JavaScript and AJAX to interact with RESTful APIs.
    /// It showcases how to implement CRUD operations without full page refreshes,
    /// resulting in a more responsive and interactive user experience.
    /// </remarks>
    public class EmployeeSinglePageController : BaseController
    {
        private readonly ILogger<EmployeeSinglePageController> _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="EmployeeSinglePageController"/> class.
        /// </summary>
        /// <param name="configuration">Application configuration interface</param>
        /// <param name="hostEnvironment">Web hosting environment information</param>
        /// <param name="logger">Logger for diagnostic information</param>
        public EmployeeSinglePageController(
            IConfiguration configuration,
            IWebHostEnvironment hostEnvironment,
            ILogger<EmployeeSinglePageController> logger) : base(configuration, hostEnvironment)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        /// <summary>
        /// Renders the Single Page Application view
        /// </summary>
        /// <returns>The SPA view that will be populated with data via AJAX</returns>
        [HttpGet]
        public IActionResult Index()
        {
            _logger.LogInformation("SPA Employee page accessed");
            return View();
        }
    }
}
