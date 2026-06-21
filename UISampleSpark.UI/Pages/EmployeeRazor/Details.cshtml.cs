using Microsoft.AspNetCore.Mvc.RazorPages;
using System;
using System.Linq;

namespace UISampleSpark.UI.Pages.EmployeeRazor
{
    /// <summary>
    /// Model for displaying employee details through Razor Pages
    /// </summary>
    public class DetailsModel : PageModel
    {
        private readonly Core.Models.Data.EmployeeContext _context;

        /// <summary>
        /// Initializes a new instance of the <see cref="DetailsModel"/> class
        /// </summary>
        /// <param name="context">Database context for employee data</param>
        public DetailsModel(Core.Models.Data.EmployeeContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Gets or sets the employee to display details for
        /// </summary>
        public Core.Models.Data.Employee Employee { get; set; } = default!;

        /// <summary>
        /// Handles GET requests to display the employee details page
        /// </summary>
        /// <param name="id">The ID of the employee to view</param>
        /// <returns>The details page or a not found result</returns>
        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null || _context.Employees == null)
            {
                return NotFound();
            }

            Core.Models.Data.Employee? employee = await _context.Employees.FirstOrDefaultAsync(m => m.Id == id);
            if (employee == null)
            {
                return NotFound();
            }
            else
            {
                Employee = employee;
            }
            return Page();
        }
    }
}
